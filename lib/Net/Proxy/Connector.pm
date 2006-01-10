package Net::Proxy::Connector;
use strict;
use warnings;
use Carp;
use Scalar::Util qw( refaddr );
use Net::Proxy;

my %PROXY_OF;

#
# the most basic possible constructor
#
sub new {
    my ( $class, $args ) = @_;
    my $self = bless $args ? {%$args} : {}, $class;
    $self->init() if $self->can('init');
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

    # call the actual Connector method
    my $sock = $self->accept_from($listener); # FIXME may croak
    Net::Proxy->set_connector( $sock, $self );
    Net::Proxy->watch_sockets($sock);

    # connect to the destination
    my $proxy = $self->get_proxy();
    my $out   = $proxy->out_connector();
    my $peer  = eval { $out->connect(); };
    if ($@) { # connect() dies if the connection fails
        $@ =~ s/ at .*?\z//s;
        carp "connect() failed with error '$@'";
        Net::Proxy->close_sockets( $sock );
        return;
    }
    if ($peer) {    # $peer is undef for Net::Proxy::Connector::dummy
        Net::Proxy->watch_sockets($peer);
        Net::Proxy->set_connector( $peer, $out );
        Net::Proxy->set_peer( $peer, $sock );
        Net::Proxy->set_peer( $sock, $peer );
    }
    $proxy->stat_inc_opened();
    return;
}

# return raw data from the socket
sub raw_read_from {
    my ( $self, $sock ) = @_;

    # low level read on the socket
    my $close = 0;
    my $buffer;
    my $read = $sock->sysread( $buffer, 4096 );    # FIXME magic number

    # check for errors
    if ( not defined $read ) {
        carp sprintf( "Read undef from %s:%s (Error %d: %s)\n",
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
    my ($self, $sock, $data) = @_;
    my $written = $sock->syswrite( $data );
    if( ! defined $written ) {
        carp sprintf("Read undef from %s:%s (Error %d: %s)\n",
                     $sock->sockhost(), $sock->sockport(), $!, "$!");
    }
    return;
}

# the most basic possible listen()
sub raw_listen {
    my $self = shift;
    my $sock = IO::Socket::INET->new(
        Listen    => 1,
        LocalAddr => $self->{host},
        LocalPort => $self->{port},
        Proto     => 'tcp',
        ReuseAddr => 1,
    );
    die $! unless $sock;

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
    sub get_data_from { }
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
This method can use the C<raw_listen()> method to do the low-listen
listen call.

=item accept_from( $socket )

C<$socket> is a listening socket created by C<listen()>.
This method returns the connected socket.

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

