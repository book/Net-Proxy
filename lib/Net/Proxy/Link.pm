package Net::Proxy::Link;

use strict;
use warnings;
use Scalar::Util qw( refaddr );

sub set_peers {
    my ( $self, $pred, $succ ) = @_;

    my ( $p, $s ) = map { defined $_ ? refaddr $_ : '' } $pred, $succ;
    $self->{_peers}{$p} = [ $pred, $succ ];
    $self->{_peers}{$s} = [ $succ, $pred ];

    delete $self->{_peers}{$p} if $p eq $s;

    return;
}

sub peer_of {
    my ( $self, $link ) = @_;
    my $addr = defined $link ? refaddr $link : '';

    # prevent auto-vivification
    return $self->{_peers}{$addr}[1]
        if exists $self->{_peers} && exists $self->{_peers}{$addr};
    return;
}

sub delete_peer_of {
    my ( $self, $link ) = @_;
    return delete $self->{_peers}{ refaddr $link };
}

sub remove_from_chain {
    my ($self) = @_;

    for my $peers ( values %{ $self->{_peers} } ) {
        my ( $pred, $succ ) = @$peers;
        if ( $pred && $pred->isa('Net::Proxy::Link') ) {
            $pred->set_peers( $pred->peer_of($self), $succ );
            $pred->delete_peer_of($self);
        }
        if ( $succ && $succ->isa('Net::Proxy::Link') ) {
            $succ->set_peers( $succ->peer_of($self), $pred );
            $succ->delete_peer_of($self);
        }
    }
    delete $self->{_peers};
}

1;

__END__

=head1 NAME

Net::Proxy::Link - Base class for proxy chains elements

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

=cut

