package Net::Proxy::Connector;
use strict;
use warnings;
use Carp;
use Scalar::Util qw( refaddr );
use Net::Proxy;

my %PROXY_OF;
my $BUFFSIZE = 4096;

#
# the most basic possible constructor
#
sub new {
    my ( $class, $args ) = @_;
    my $self = bless $args ? {%$args} : {}, $class;
    $self->init() if $self->can('init');
    delete $self->{_proxy_}; # this link back is now unnecessary
    return $self;
}

#
# Each Connector is managed by a Net::Proxy object
#
sub set_proxy {
    my ( $self, $proxy ) = @_;
    croak "$proxy is not a Net::Proxy object"
        if !UNIVERSAL::isa( $proxy, 'Net::Proxy' );
    return $PROXY_OF{ refaddr $self } = $proxy;
}

sub get_proxy { return $PROXY_OF{ refaddr $_[0] }; }

sub is_in {
    my $id = refaddr $_[0];
    return $id == refaddr $PROXY_OF{$id}->in_connector();
}

sub is_out {
    my $id = refaddr $_[0];
    return $id == refaddr $PROXY_OF{$id}->out_connector();
}

#
# the method that creates all the sockets
#
sub new_connection_on {
    my ( $self, $listener ) = @_;
    Net::Proxy->notice(
        'New connection on ' . Net::Proxy->get_nick($listener) );

    # call the actual Connector method
    my $sock = eval { $self->accept_from($listener); };
    if( $@ ) {
        Net::Proxy->error( $@ );
        return;
    }

    Net::Proxy->set_connector( $sock, $self );
    Net::Proxy->set_buffer( $sock, '' );
    Net::Proxy->set_callback( $sock, $self->{hook} ) if $self->{hook};
    Net::Proxy->watch_reader_sockets($sock);

    # connect to the destination
    my $out = $self->get_proxy()->out_connector();
    $out->_out_connect_from($sock);

    # update the stats
    $self->get_proxy()->stat_inc_opened();
    return;
}

sub _out_connect_from {
    my ( $self, $sock ) = @_;

    my $peer = eval { $self->connect(); };
    if ($@) {    # connect() dies if the connection fails
        $@ =~ s/ at .*?\z//s;
        warn "connect() failed with error '$@'\n";
        Net::Proxy->close_sockets($sock);
        return;
    }
    if ($peer) {    # $peer is undef for Net::Proxy::Connector::dummy
        Net::Proxy->watch_reader_sockets($peer);
        Net::Proxy->set_connector( $peer, $self );
        Net::Proxy->set_buffer( $peer, '' );
        Net::Proxy->set_callback( $peer, $self->{hook} ) if $self->{hook};
        Net::Proxy->set_nick( $peer,
                  $peer->sockhost() . ':'
                . $peer->sockport() . ' -> '
                . $peer->peerhost() . ':'
                . $peer->peerport() );
        Net::Proxy->notice( 'Connected ' . Net::Proxy->get_nick( $peer ) );

        Net::Proxy->set_peer( $peer, $sock );
        Net::Proxy->set_peer( $sock, $peer );
        Net::Proxy->notice( 'Peered '
                . Net::Proxy->get_nick($sock) . ' with '
                . Net::Proxy->get_nick($peer) );
    }

    return;
}

#
# base methods for exchanging raw data
#

# return raw data from the socket
sub raw_read_from {
    my ( $self, $sock ) = @_;

    # low level read on the socket
    my $close = 0;
    my $buffer;
    my $read = $sock->sysread( $buffer, $BUFFSIZE );

    ## Net::Proxy->debug("Read $read bytes from " . Net::Proxy->get_nick($sock));

    # check for errors
    if ( not defined $read ) {
        warn sprintf( "Read undef from %s:%s (Error %d: %s)\n",
            $sock->sockhost(), $sock->sockport(), $!, "$!" );
        $close = 1;
    }

    # connection closed
    if ( $close || $read == 0 ) {
        my $peer = Net::Proxy->get_peer($sock);
        $self->get_proxy()->close_sockets( $sock, $peer );
        return;
    }

    return $buffer;
}

# send raw data to the socket
sub raw_write_to {
    my ($self, $sock) = @_;
    my $data = Net::Proxy->get_buffer( $sock );

    ## Net::Proxy->debug("Writing @{[length $data]} bytes (max $BUFFSIZE) to " . Net::Proxy->get_nick($sock));

    my $written = $sock->syswrite( $data, $BUFFSIZE );

    ## Net::Proxy->debug("Wrote $written bytes to " . Net::Proxy->get_nick($sock));
    if( ! defined $written ) {
        warn sprintf("Read undef from %s:%s (Error %d: %s)\n",
                     $sock->sockhost(), $sock->sockport(), $!, "$!");
    }
    elsif ( $written == length $data ) {
        Net::Proxy->remove_writer_sockets( $sock );
        Net::Proxy->set_buffer( $sock, '' );
    }
    else { # there is some data left to write
        Net::Proxy->set_buffer( $sock, substr( $data, $written ) );
    }
    return;
}

#
# base methods for listen() and accept_from()
#

# the most basic possible listen()
sub raw_listen {
    my $self = shift;
    my $sock = IO::Socket::INET->new(
        Listen    => 1,
        LocalAddr => $self->{host},
        LocalPort => $self->{port},
        Proto     => 'tcp',
        ReuseAddr => $^O eq 'MSWin32' ? 0 : 1,
    );

    # this exception is not catched by Net::Proxy
    die "Can't listen on $self->{host} port $self->{port}: $!" unless $sock;

    Net::Proxy->set_nick( $sock,
        'listener ' . $sock->sockhost() . ':' . $sock->sockport() );

    return $sock;
}

# accept on a socket and return the new connected socket
sub raw_accept_from {
    my ($self, $listen) = @_;
    my $sock = $listen->accept();
    die $! unless $sock;

    Net::Proxy->set_nick( $sock,
              $sock->peerhost() . ':'
            . $sock->peerport() . ' -> '
            . $sock->sockhost() . ':'
            . $sock->sockport() );
    Net::Proxy->notice( 'Accepted ' . Net::Proxy->get_nick( $sock ) );

    return $sock;
}

1;

__END__

=head1 NAME

Net::Proxy::Connector - Base class for Net::Proxy protocols

=head1 SYNOPSIS

    #
    # template for the zlonk connector
    #
    package Net::Proxy::Connector::zlonk;

    use strict;
    use Net::Proxy::Connector;
    our @ISA = qw( Net::Proxy::Connector );

    # here are the methods you need to write for your connector

    # if it can be used as an 'in' connector
    sub listen { }
    sub accept_from { }

    # if it can be used as an 'out' connector
    sub connect { }

    # to process data
    sub read_from { }
    sub write_to { }

    1;

=head1 DESCRIPTION

C<Net::Proxy::Connector> is the base class for all specialised
protocols used by C<Net::Proxy>.

=head1 METHODS

=head2 Class methods

The base class provides the following methods:

=over 4

=item new()

=back

=head2 Instance methods

=over 4

=item set_proxy( $proxy )

Define the proxy that "owns" the connector.

=item get_proxy()

Return the C<Net::Proxy> object that "owns" the connector.

=item is_in()

Return a boolean value indicating if the C<Net::Proxy::Connector>
object is the C<in> connector of its proxy.

=item is_out()

Return a boolean value indicating if the C<Net::Proxy::Connector>
object is the C<out> connector of its proxy.

=item new_connection_on( $socket )

This method is called by C<Net::Proxy> to handle incoming connections,
and in turn call C<accept_from()> on the 'in' connector and
C<connect()> on the 'out' connector.

=item raw_read_from( $socket )

This method can be used by C<Net::Proxy::Connector> subclasses in their
C<read_from()> methods, to fetch raw data on a socket.

=item raw_write_to( $socket, $data )

This method can be used by C<Net::Proxy::Connector> subclasses in their
C<write_to()> methods, to send raw data on a socket.

=item raw_listen( )

This method can be used by C<Net::Proxy::Connector> subclasses in their
C<listen()> methods, to create a listening socket on their C<host>
and C<port> parameters.

=item raw_accept_from( $socket )

This method can be used internaly by C<Net::Proxy::Connector> subclasses
in their C<accept_from()> methods, to accept a newly connected socket.

=back

=head1 Subclass methods

The following methods should be defined in C<Net::Proxy::Connector>
subclasses:

=head2 Initialisation

=over 4

=item init()

This method initalise the connector.

=back

=head2 Processing incoming/outgoing data

=over 4

=item read_from( $socket )

Return the data that was possibly decapsulated by the connector.

=item write_to( $socket, $data )

Write C<$data> to the given C<$socket>, according to the connector
scheme.

=back

=head2 C<in> connector

=over 4

=item listen()

Initiate listening sockets and return them.

This method can use the C<raw_listen()> method to do the low-level
listen call.

=item accept_from( $socket )

C<$socket> is a listening socket created by C<listen()>.
This method returns the connected socket.

This method can use the C<raw_accept_from()> method to do the low-level
accept call.

=back

=head2 C<out> connector

=over 4

=item connect()

Return a socket connected to the remote server.

=back

=head1 AUTHOR

Philippe 'BooK' Bruhat, C<< <book@cpan.org> >>.

=head1 COPYRIGHT

Copyright 2006 Philippe 'BooK' Bruhat, All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

