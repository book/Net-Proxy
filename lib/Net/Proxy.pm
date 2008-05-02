package Net::Proxy;
use strict;
use warnings;
use Carp;
use Scalar::Util qw( refaddr reftype );
use IO::Select;
use POSIX 'strftime';

our $VERSION = '0.20';

use Net::Proxy::Message;
use Net::Proxy::MessageQueue;

# internal socket information table
my %OWNER_OF;
my %CLOSING;
my $READERS = IO::Select->new();
my $WRITERS = IO::Select->new();
my $SOCKETS = IO::Select->new();
my %PROXY;
my %STATS;
my %LISTENER;

# Net::Proxy attributes
my $VERBOSITY = 0; # be silent by default

#
# some logging-related methods
#
sub set_verbosity { $VERBOSITY = $_[1]; }
{
    my $i;
    for my $meth (qw( error notice info debug )) {
        no strict 'refs';
        my $level = $i++;
        *$meth = sub {
            return if $VERBOSITY < $level;
            print STDERR strftime "%Y-%m-%d %H:%M:%S $_[1]\n", localtime;
        };
    }
}

#
# constructor
#
sub new {
    my ( $class, $args ) = @_;
    my $self = bless \do { my $anon }, $class;

    croak "Argument to new() must be a HASHREF" if ref $args ne 'HASH';

    my @args;
    for my $conn (qw( in out )) {

        # check arguments
        croak "'$conn' connector required" if !exists $args->{$conn};

        croak "'$conn' connector must be a HASHREF"
            if ref $args->{$conn} ne 'HASH';

        croak "'type' key required for '$conn' connector"
            if !exists $args->{$conn}{type};

        croak "'hook' key is not a CODE reference for '$conn' connector"
            if $args->{$conn}{hook}
            && reftype( $args->{$conn}{hook} ) ne 'CODE';

        # compatibility layer
        if( $conn eq 'in' ) {
           $args->{$conn}{Listen} = 1 if $args->{$conn}{type} eq 'tcp';
        }
 
        # call chain with the same parameters
        push @args, $args->{$conn};
    }

    return Net::Proxy->chain( @args );
}

sub chain {
    my ( $class, @comps ) = @_;

    # basic check
    croak 'All chain() parameters must be HASHREF'
        if grep { ref $_ ne 'HASH' } @comps;

    my $chain;
    my $prev;

    # create the whole chain
    my $i = 1;
    for my $comp (@comps) {

        # check arguments
        croak "'type' key required for component $i"
            if !exists $comp->{type};

        # load the component class
        my $module = 'Net::Proxy::Component::' . $comp->{type};
        eval "require $module; 1;"
            or croak
            "Couldn't load $module for component $i ($comp->{type}): $@";

        # compute the factory class name
        my $class = 'Net::Proxy::ComponentFactory::' . $comp->{type};
        my $fact  = $class->new($comp);

        # set the beginning of the chain
        $chain ||= $fact;
        if ($prev) {
            $prev->set_next( in  => $fact );
            $fact->set_next( out => $prev );
        }
        $prev = $fact;
        $i++;
    }

    return $chain;
}

sub register { $PROXY{ refaddr $_[1] } = $_[1]; }
sub unregister { delete $PROXY{ refaddr $_[1] }; }

sub set_compdir_for {
    my ( $class, $sock, $comp, $direction ) = @_;
    $OWNER_OF{ refaddr $sock } = [ $comp, $direction ];
    $SOCKETS->add( $sock );
}

sub get_compdir_for {
    my ( $class, $sock ) = @_;
    return @{ $OWNER_OF{ refaddr $sock } || [] };
}

#
# create statistical methods
#
for my $info (qw( opened closed )) {
    no strict 'refs';
    *{"stat_inc_$info"} = sub {
        $STATS{ refaddr $_[0]}{$info}++;
        $STATS{total}{$info}++;
    };
    *{"stat_$info"}       = sub { $STATS{ refaddr $_[0]}{$info} || 0; };
    *{"stat_total_$info"} = sub { $STATS{total}{$info} || 0; };
}

#
# socket-related methods
#
sub close_sockets {
    my ( $class, @socks ) = @_;

  SOCKET:
    for my $sock (@socks) {

        # FIXME
        #Net::Proxy->notice( 'Closing ' . Net::Proxy->get_nick( $sock ) );

        # FIXME stats

        # clean up internal structures
        delete $LISTENER{ refaddr $sock};
        delete $CLOSING{ refaddr $sock};

        # clean up sockets
        $READERS->remove($sock);
        $WRITERS->remove($sock);
        $SOCKETS->remove($sock);
        $sock->close();
    }

    return;
}

#
# select() stuff
#
sub watch_reader_sockets {
    my ( $class, @socks ) = @_;
    $READERS->add(@socks);
    return;
}

sub remove_reader_sockets {
    my ( $class, @socks ) = @_;
    $READERS->remove(@socks);
    return;
}

sub watch_writer_sockets {
    my ( $class, @socks ) = @_;
    $WRITERS->add(@socks);
    return;
}

sub remove_writer_sockets {
    my ( $class, @socks ) = @_;
    $WRITERS->remove(@socks);
    return;
}

#
# the mainloop itself
#
sub mainloop {
    my ( $class, $max_connections ) = @_;
    $max_connections ||= 0;

    # initialise all proxies
    for my $chain ( values %PROXY ) {
        Net::Proxy::MessageQueue->queue( [ undef, $chain, 'in',
            Net::Proxy::Message->new( 'm_START_PROXY' => { factory => 1 } ) ] );
    }

    my $continue = 1;
    for my $signal (qw( INT HUP )) {
        $SIG{$signal} = sub {
            Net::Proxy->notice("Caught $signal signal");
            $continue = 0;
            exit; # FIXME 
        };
    }

    # loop indefinitely
    while (1) {

        # process all available messages
        while ( my $msg_ctx = Net::Proxy::MessageQueue->next() ) {
            my ( $from, $to, $direction, $message ) = @$msg_ctx;
            $to->process( $message, $from, $direction );
        }

        # get the $timeout from the message queue information
        # (it's the time remaining until the next timed message)
        # only timed messages should remain in the queue
        my @msgs = qw( m_CAN_READ m_CAN_WRITE m_HAS_EXCEPTION );
        my %can;
        @can{@msgs} = IO::Select->select( $READERS, $WRITERS, $SOCKETS,
            Net::Proxy::MessageQueue->timeout() );

        # send m_CAN_READ, m_CAN_WRITE and m_HAS_EXCEPTION messages
        # to the owners of the sockets that are ready
        for my $msg (@msgs) {
            for my $sock ( @{ $can{$msg} } ) {
                my ( $node, $direction ) = Net::Proxy->get_compdir_for($sock);
                Net::Proxy::MessageQueue->queue(
                    [   $sock,      $node,
                        $direction, Net::Proxy::Message->new($msg)
                    ]
                );
            }
        }

        # in case we have a limit on incoming connections
        if( $max_connections ) {

            # stop after that many connections
            last if Net::Proxy->stat_total_closed() == $max_connections;

            # prevent new connections
            if ( %LISTENER
                && Net::Proxy->stat_total_opened() == $max_connections )
            {
                Net::Proxy->close_sockets( values %LISTENER );
            }
        }
    }

    # close all remaining sockets
    Net::Proxy->close_sockets( $SOCKETS->handles() );
}
 
1;

__END__

=head1 NAME

Net::Proxy - Framework for proxying network connections in many ways

=head1 SYNOPSIS

    use Net::Proxy;

    # proxy connections from localhost:6789 to remotehost:9876
    # using standard TCP connections

    # new interface
    my $proxy = Net::Proxy->new(
        { type => 'tcp', port => '6789', Listen => 1 },
        { type => 'tcp', host => 'remotehost', port => '9876' },
    );

    # old interface
    my $proxy = Net::Proxy->new(
        {   in  => { type => 'tcp', port => '6789' },
            out => { type => 'tcp', host => 'remotehost', port => '9876' },
        }
    );

    # register the proxy object
    $proxy->register();

    # and you can setup multiple proxies

    # and now proxy connections indefinitely
    Net::Proxy->mainloop();

=head1 DESCRIPTION

A C<Net::Proxy> object represents a proxy that accepts connections
and then relays the data transfered between the source and the destination.

The goal of this module is to abstract the different methods used
to connect from the proxy to the destination.

A proxy is a program that transfer data across a network boundary           
between a client and a server. C<Net::Proxy> introduces the concept of         
"components" (implemented as C<Net::Proxy::Component> subclasses),
which abstract the server part (connected to the client),
the intermediate filters (that can operate on the data flowing through the proxy),
and the client part (connected to the server) of the proxy.         
                                                                            
This architecture makes it easy to implement specific techniques to
cross a given network boundary, possibly by using a proxy on one side
of the network fence, and a reverse-proxy on the other side of the fence.

See L<AVAILABLE COMPONENTS> for details about the existing connectors.

=head1 METHODS

If you only intend to use C<Net::Proxy> and not write new
connectors, you only need to know about C<new()>, C<register()>
and C<mainloop()>.

=head2 Class methods

=over 4

=item new( { in => { ... }, { out => { ... } } )

Return a new C<Net::Proxy> object, with two connectors configured
as described in the hashref.

The connector parameters are described in the table below, as well
as in each connector documentation.

=item mainloop( $max_connections )

This method initialises all the registered C<Net::Proxy> objects
and then loops on all the sockets ready for reading, passing
the data through the various C<Net::Proxy::Connector> objets
to handle the specifics of each connection.

If C<$max_connections> is given, the proxy will stop after having fully
processed that many connections. Otherwise, this method does not return.

=item add_listeners( @sockets )

Add the given sockets to the list of listening sockets.

=item watch_reader_sockets( @sockets )

Add the given sockets to the readers watch list.

=item watch_writer_sockets( @sockets )

Add the given sockets to the writers watch list.

=item remove_writer_sockets( @sockets )

Remove the given sockets from the writers watch list.

=item close_sockets( @sockets )

Close the given sockets and cleanup the related internal structures.

=item set_verbosity( $level )

Set the logging level. C<0> means not messages except warnings and errors.

=item error( $message )

Log $message to STDERR, always.

=item notice( $message )

Log $message to STDERR if verbosity level is equal to C<1> or more.

=item info( $message )

Log $message to STDERR if verbosity level is equal to C<2> or more.

=item debug( $message )

Log $message to STDERR if verbosity level is equal to C<3> or more.

(Note: throughout the C<Net::Proxy> source code, calls to C<debug()> are
commented with C<##>.)

=back

Some of the class methods are related to the socket objects that handle
the actual connections.

=over 4

=item get_peer( $socket )

=item set_peer( $socket, $peer )

Get or set the socket peer.

=item get_connector( $socket )

=item set_connector( $socket, $connector )

Get or set the socket connector (a C<Net::Proxy::Connector> object).

=item get_state( $socket )

=item set_state( $socket, $state )

Get or set the socket state. Some C<Net::Proxy::Connector> subclasses
may wish to use this to store some internal information about the
socket or the connection.

=item get_nick( $socket )

=item set_nick( $socket, $nickname )

Get or set the socket nickname. Typically used by C<Net::Proxy::Connector>
to give informative names to socket (used in the log messages).

=item get_buffer( $socket )

=item set_buffer( $socket, $data )

Get or set the content of the writing buffer for the socket.
Used by C<Net::Proxy::Connector> in C<raw_read_from()> and
C<ranw_write_to()>.

=item get_callback( $socket )

=item set_callback( $socket, $coderef )

Get or set the callback currently associated with the socket.

=item add_to_buffer( $socket, $data )

Add data to the writing buffer of the socket.

=back

=head2 Instance methods

=over 4

=item register()

Register a C<Net::Proxy> object so that it will be included in
the C<mainloop()> processing.

=item unregister()

Unregister the C<Net::Proxy> object.

=item in_connector()

Return the C<Net::Proxy::Connector> objet that handles the incoming
connection and handles the data coming from the "client" side.

=item out_connector()

Return the C<Net::Proxy::Connector> objet that creates the outgoing 
connection and handles the data coming from the "server" side.

=back

=head2 Statistical methods

The following methods manage some statistical information
about the individual proxies:

=over 4

=item stat_inc_opened()

=item stat_inc_closed()

Increment the "opened" or "closed" connection counter for this proxy.

=item stat_opened()

=item stat_closed()

Return the count of "opened" or "closed" connections for this proxy.

=item stat_total_opened()

=item stat_total_closed()

Return the total count of "opened" or "closed" connection across
all proxy objects.

=back

=head1 CONNECTORS

All connection types are provided with the help of specialised classes.
The logic for protocol C<xxx> is provided by the C<Net::Proxy::Connector::xxx>
class.

=head2 Connector hooks

There is a single parameter that all connectors accept: C<hook>.
Given a code reference, the code reference will be called when
data is I<received> on the corresponding socket.

The code reference should have the following signature:

    sub callback {
        my ($dataref, $sock, $connector) = @_;
        ...
    }

C<$dataref> is a reference to the chunk of data received,
C<$sock> is a reference to the socket that received the data, and
C<$connector> is the C<Net::Proxy::Connector> object that created the
socket. This allows someone to eventually store data in a stash stored
in the connector, so as to share data between sockets.

=head2 Available connectors

=over 4

=item * tcp (C<Net::Proxy::Connector::tcp>)

This is the simplest possible proxy connector. On the "in" side, it sits waiting
for incoming connections, and on the "out" side, it connects to the
configured host/port.

=item * connect (C<Net::Proxy::Connector::connect>)

This proxy connector can connect to a TCP server though a web proxy that
accepts HTTP CONNECT requests.

=item * dual (C<Net::Proxy::Connector::dual>)

This proxy connector is a Y-shaped connector: depending on the client behaviour
right after the connection is established, it connects it to one
of two services, handled by two distinct connectors.

=item * dummy (C<Net::Proxy::Connector::dummy>)

This proxy connector does nothing. You can use it as a template for writing
new C<Net::Proxy::Connector> classes.

=back

=head2 Summary

This table summarises all the available C<Net::Proxy::Connector>
classes and the parameters their constructors recognise.

C<N/A> means that the given C<Net::Proxy::Connector> cannot be used
in that position (either C<in> or C<out>).

     Connector  | in parameters   | out parameters
    ------------+-----------------+-----------------
     tcp        | host            | host
                | port            | port
    ------------+-----------------+-----------------
     connect    | N/A             | host
                |                 | port
                |                 | proxy_host
                |                 | proxy_port
                |                 | proxy_user
                |                 | proxy_pass
                |                 | proxy_agent
    ------------+-----------------+-----------------
     dual       | host            | N/A
                | port            |
                | timeout         |
                | server_first    |
                | client_first    |
    ------------+-----------------+-----------------
     dummy      | N/A             | N/A
    ------------+-----------------+-----------------
     ssl        | host            | host
                | port            | port
                | start_cleartext | start_cleartext
    ------------+-----------------+-----------------
     connect_ssl| N/A             | host
                |                 | port
                |                 | proxy_host
                |                 | proxy_port
                |                 | proxy_user
                |                 | proxy_pass
                |                 | proxy_agent

C<Net::Proxy::Connector::dummy> is used as the C<out> parameter for
a C<Net::Proxy::Connector::dual>, since the later is linked to two
different connector objects.

=head1 AUTHOR

Philippe 'BooK' Bruhat, C<< <book@cpan.org> >>.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-proxy@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/>. I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 TODO

Here's my own wishlist:

=over 4

=item *

Write a connector fully compatible with GNU httptunnel
(L<http://www.nocrew.org/software/httptunnel.html>).

This one will probably be named C<Net::Proxy::Connector::httptunnel>.

=item *

Enhance the httptunnel protocol to support multiple connections.

=item *

Implement RFC 3093 - Firewall Enhancement Protocol (FEP), as
C<Net::Proxy::Connector::FEP>. This RFC was published on April 1, 2001.

This is probably impossible with C<Net::Proxy>, since the FEP driver is
a rather low-level driver (at the IP level of the network stack).

=item *

Implement DNS tunnel connectors.

See L<http://savannah.nongnu.org/projects/nstx/>,
OzymanDNS, L<http://www.doxpara.com/slides/BH_EU_05-Kaminsky.pdf>.
L<http://thomer.com/howtos/nstx.html> for examples.

=item *

Implement an UDP connector. (Is it feasible?)

=item *

Implement a connector that can be plugged to the STDIN/STDOUT of an
external process, like the C<ProxyCommand> option of OpenSSH.

=item *

Implement C<Net::Proxy::Connector::unix>, for UNIX sockets.

=item *

Implement ICMP tunnel connectors.

See
L<http://www.linuxexposed.com/Articles/Hacking/Case-of-a-wireless-hack.html>,
L<http://sourceforge.net/projects/itun>,
L<http://www.cs.uit.no/~daniels/PingTunnel/>,
L<http://thomer.com/icmptx/> for examples.

Since ICMP implies low-level packet reading and writing, it may not be
possible for C<Net::Proxy> to handle it.

=item *

Look for inspiration in the I<Firewall-Piercing HOWTO>, 
at L<http://fare.tunes.org/files/fwprc/>.

Look also here: L<http://gray-world.net/tools/>

=item *

Implement a C<Net::Proxy::Connector::starttls> connector that can upgrade
upgrade a connection to SSL transparently, even if the client or server
doesn't support STARTTLS.

Martin Werthmöller provided a full implementation of a connector that
can handle IMAP connections and upgrade them to TLS if the client sends
a C<STARTTLS> command. My implementation will split this in two parts
C<Net::Proxy::Connector::ssl> and C<Net::Proxy::Connector::starttls>,
that inherits from the former.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Proxy

You can also look for information at:

=over 4

=item * The Net::Proxy mailing-list

L<http://listes.mongueurs.net/mailman/listinfo/net-proxy/>

This list receive an email for each commit

=item * The public source repository

svn://svn.mongueurs.net/Net-Proxy/trunk/

Also available through a web interface at
L<http://svnweb.mongueurs.net/Net-Proxy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Proxy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Proxy>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Proxy>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Proxy>

=back

=head1 COPYRIGHT

Copyright 2006-2007 Philippe 'BooK' Bruhat, All Rights Reserved.
 
=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

