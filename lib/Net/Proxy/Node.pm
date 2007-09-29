package Net::Proxy::Node;

use strict;
use warnings;
use Scalar::Util qw( refaddr );

sub next {
    my ($self, $direction ) = @_;
    return $self->{"_next_$direction"};
}

sub last {
    my ($self, $direction ) = @_;
    my $next = $self->next( $direction );
    return if !$next;

    my $last = $next;
    $last = $next while $next = $next->next( $direction);
    return $last;
}

sub set_next {
    my ($self, $direction, $next ) = @_;
    return $self->{"_next_$direction"} = $next;
}


1;

__END__

=head1 NAME

Net::Proxy::Node - Base class for proxy chains elements

=head1 SYNOPSIS

    # $comp isa Net::Proxy::Node
    $comp->set_next( in => $next_comp );
    $next = $comp->next('in');    # $next_comp;

=head1 DESCRIPTION

C<Net::Proxy;:Node> is a simple class used to represent the chains
of C<Net::Proxy::Components> and C<Net::Proxy::ComponentFactory>
objects used in C<Net::Proxy>.

Both classes inherit from C<Net::Proxy::Node> a default implementation
of the following methods:

=over 4

=item next( $direction )

Return the next item in the chain, following direction C<$direction>
(C<in> or C<out>).

=item set_next( $direction )

Set the next item in the chain, when following direction C<$direction>.

=head1 AUTHOR

Philippe Bruhat (BooK)

=cut

