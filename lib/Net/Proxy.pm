package Net::Proxy;
use strict;
use warnings;
use Carp;
use Scalar::Util qw( refaddr );
use IO::Select;

our $VERSION = '0.01';

# interal socket information table
my %SOCK_INFO;
my %LISTENER;
my $SELECT;
my %PROXY;

# Net::Proxy attributes
my %CONNECTOR = (
   in  => {},
   out => {},
);

#
# constructor
#
sub new {
    my ( $class, $args ) = @_;

    my $self = bless \do{my $anon}, $class;

    croak "Argument to new() must be a HASHREF" if ref $args ne 'HASH';

    for my $conn (qw( in out )) {

        # check arguments
        croak "'$conn' connector required" if !exists $args->{$conn};

        croak "'$conn' connector must be a HASHREF"
            if ref $args->{$conn} ne 'HASH';

        croak "'type' key required for '$conn' connector'"
            if !exists $args->{$conn}{type};

        # load the class
        my $class = 'Net::Proxy::Connector::' . $args->{$conn}{type};
        eval "require $class";
        croak "Couldn't load $class for '$conn' connector" if $@;

        # create and store the Connector object
        $CONNECTOR{$conn}{refaddr $self} = $class->new( $args->{$conn} );
        $CONNECTOR{$conn}{refaddr $self}->set_proxy( $self );
    }

    return $self;
}

sub register { $PROXY{ refaddr $_[0] } = $_[0]; }
sub unregister { delete $PROXY{ refaddr $_[0] }; }

#
# The Net::Proxy attributes
#
sub in_connector  { return $CONNECTOR{in}{ refaddr $_[0] }; }
sub out_connector { return $CONNECTOR{out}{ refaddr $_[0] }; }

#
# create the socket setter/getter methods
# these are actually Net::Proxy clas methods
#
{
    my $n = 0;
    for my $attr (qw( peer connector state )) {
        no strict 'refs';
        my $i = $n;
        *{"get_$attr"} = sub { $SOCK_INFO{ refaddr $_[1] }[$i]; };
        *{"set_$attr"} = sub { $SOCK_INFO{ refaddr $_[1] }[$i] = $_[2]; };
        $n++;
    }
}

#
# socket-related methods
#
sub add_listeners {
    my ( $class, @socks ) = @_;
    for my $sock (@socks) {
        $LISTENER{ refaddr $sock} = 1;
    }
    return;
}

# this one will explode if $SELECT is undef
sub watch_sockets {
    my ( $class, @socks ) = @_;
    $SELECT->add(@socks);
    return;
}

sub close_sockets {
    my ( $class, @socks ) = @_;

    for my $sock (@socks) {

        # clean up connector
        my $conn = Net::Proxy->get_connector($sock);
        $conn->close($sock) if $conn->can('close');

        # clean up internal structures
        delete $SOCK_INFO{ refaddr $sock};
        delete $LISTENER{ refaddr $sock};

        # clean up sockets
        $SELECT->remove($sock);
        $sock->close();
    }

    return;
}

#
# destructor
#
sub DESTROY {
    my ($self) = @_;
    delete $CONNECTOR{in}{ refaddr $self};
    delete $CONNECTOR{out}{ refaddr $self};
}

#
# the mainloop itself
#
sub mainloop {

    $SELECT = IO::Select->new();

    # initialise all proxies
    for my $proxy ( values %PROXY ) {
        my $in = $proxy->in_connector();
        my @socks = $in->listen();
        Net::Proxy->add_listeners(@socks);
        Net::Proxy->watch_sockets(@socks);
        Net::Proxy->set_connector( $_, $in ) for @socks;
    }

    # loop indefinitely
    while ( my @ready = $SELECT->can_read() ) {
       SOCKET:
        for my $sock (@ready) {
            if ( _is_listener($sock) ) {

                # FIXME eval {} for failure
                # accept the new connection and connect to the destination
                Net::Proxy->get_connector($sock)->new_connection_on($sock);
            }
            else {

                # read the data
                my $peer = Net::Proxy->get_peer($sock);
                my $data
                    = Net::Proxy->get_connector($sock)->get_data_from($sock);
                next SOCKET if ! defined $data;

                # TODO filtering by the proxy

                Net::Proxy->get_connector($peer)->write_to( $peer, $data );
            }
        }
    }
}

#
# helper private FUNCTIONS
#
sub _is_listener { return exists $LISTENER{ refaddr $_[0] }; }

1;

__END__

=head1 NAME

Net::Proxy - Proxy network connections using various protocols

=head1 SYNOPSIS

    use Net::Proxy;

    # proxy connections from localhost:6789 to remotehost:9876
    # using standard TCP connections
    my $proxy = Net::Proxy->new(
        in  => { proto => tcp, port => '6789' },
        out => { proto => tcp, host => 'remotehost', port => '9876' },
    );

    # register the proxy object
    $proxy->register();

    # and now proxy connections indefinitely
    Net::Proxy->mainloop();

=head1 DESCRIPTION

A C<Net::Proxy> object represents a proxy that accepts connections
and then relays the data transfered between the source and the destination.

The goal of this module is to abstract the different protocols used
to connect from the proxy to the destination.

=head1 METHODS

=head2 Class methods

=over 4

=item new( )

=item mainloop()

This method initialises all the registered C<Net::Proxy> objects
and then loops on all the sockets ready for reading, passing
the data through the various C<Net::Proxy::Connector> objets
to handle the specifics of each connection.

This method does not return.

=back

Some of the class methods are related to the socket objects handling
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

Get or set the socket state. Some C<Net::Proxy::Connector> classes
may wish to use this to store some internal information about the
socket or the connection.

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

=head1 AVAILABLE PROTOCOLS

All protocols are provided with the help of specialised classes.
The logic for protocol C<xxx> is provided by the C<Net::Proxy::Connector::xxx>
class.

=head2 tcp (C<Net::Proxy::tcp>)

=head2 Summary

This table summarises all the available C<Net::Proxy::Connector>
classes and the parameters they recognise.

     Connector  | in parameters   | out parameters
    ------------+-----------------+----------------
     tcp        | host            | host
                | port            | port
    ------------+-----------------+----------------
     connect    | N/A             | host
                |                 | port
                |                 | proxy_host
                |                 | proxy_port
                |                 | proxy_user
                |                 | proxy_pass
                |                 | proxy_agent
    ------------+-----------------+----------------
     httptunnel |                 |
    ------------+-----------------+----------------
     dual       |                 | N/A
    ------------+-----------------+----------------
     dummy      | N/A             | N/A

=head1 AUTHOR

=head1 COPYRIGHT

=head1 LICENSE


=cut

