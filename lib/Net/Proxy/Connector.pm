package Net::Proxy::Connector;
use strict;
use warnings;
use Carp;
use Scalar::Util qw( refaddr );

my %PROXY_OF;

#
# the most basic constructor possible
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
    my $sock = $self->accept_from($listener);
    Net::Proxy->set_connector( $sock, $self );
    Net::Proxy->watch_sockets($sock);

    # connect to the destination
    my $out  = $self->get_proxy()->out_connector();
    my $peer = $out->connect();
    if ($peer) {    # $peer is undef for Net::Proxy::Connector::dummy
        Net::Proxy->watch_sockets($peer);
        Net::Proxy->set_connector( $peer, $self );
        Net::Proxy->set_peer( $peer, $sock );
        Net::Proxy->set_peer( $sock, $peer );
    }

    return;
}

# return raw data from the socket
sub raw_data_from {
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

1;

__END__

=head1 NAME

Net::Proxy::Connector - Base class for Net::Proxy protocols

=head1 SYNOPSIS

    package Net::Proxy::Connector::zlonk;

    use strict;
    our @ISA = qw( Net::Proxy::Connector );

    # if it can be used as an 'in' connector
    sub listen { }
    sub accept_from { }

    # if it can be used as an 'out' connector
    sub open_connection { }

    # to process data
    sub get_data_from { }

    1;

=head1 DESCRIPTION

C<Net::Proxy::Connector> is the base class for all specialised
protocols used by C<Net::Proxy>.

=head1 METHODS

=head2 Class methods

The base class provides the following methods:

=over 4

=item new()

=item manager_of( $sock )

=back

=head2 Instance methods

=over 4

=item register_as_manager_of( $sock )

=item set_peer( $proto )

=item get_peer()

=back

=head1 AUTHOR

=head1 COPYRIGHT

=head1 LICENSE

