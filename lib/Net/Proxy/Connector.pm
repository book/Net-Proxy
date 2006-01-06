package Net::Proxy::Connector;
use strict;
use warnings;
use Carp;
use Scalar::Util qw( refaddr );

my %PROXY_OF;

#
# the most basic possible constructor
#
sub new {
    my ( $class, $args ) = @_;
    return bless $args ? {%$args} : {}, $class;
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
    my $out  = $self->get_proxy()->out_connector();
    my $peer = $out->connect();
    if ($peer) {    # $peer is undef for Net::Proxy::Connector::dummy
        Net::Proxy->watch_sockets($peer);
        Net::Proxy->set_connector( $peer, $out );
        Net::Proxy->set_peer( $peer, $sock );
        Net::Proxy->set_peer( $sock, $peer );
    }

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
    if ( $read == 0 || $close ) {
        $self->get_proxy()->close_sockets($sock);
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

=back

=head1 Subclass methods

The following methods should be defined in C<Net::Proxy::Connector>
subclasses:

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

=head1 COPYRIGHT & LICENSE

Copyright 2006 Philippe 'BooK' Bruhat, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

