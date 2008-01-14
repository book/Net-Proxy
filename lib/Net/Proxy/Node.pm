package Net::Proxy::Node;

use strict;
use warnings;
use Scalar::Util qw( blessed );

sub next {
    my ( $self, $direction ) = @_;
    return $self->{"_next_$direction"};
}

sub last {
    my ( $self, $direction ) = @_;
    my $next = $self->next($direction);
    return if !$next;

    my $last = $next;
    $last = $next
        while $next = blessed $next
        && $next->isa('Net::Proxy::Node')
        && $next->next($direction);
    return $last;
}

sub set_next {
    my ( $self, $direction, $next ) = @_;
    return $self->{"_next_$direction"} = $next;
}

sub act_on {
    my ( $self, $message, $from, $direction ) = @_;

    # skip actions if the chain is unidirectional
    return $message if $self->{only} && $self->{only} ne $direction;

    my $action = $message->type();
    return $self->can($action)
        ? $self->$action( $message, $from, $direction )    # process msg
        : $message;                                        # just keep it
}

1;

__END__

=head1 NAME

Net::Proxy::Node - Chain navigation mixin class

=head1 SYNOPSIS

    # $comp isa Net::Proxy::Node
    $comp->set_next( in => $next_comp );
    $next = $comp->next('in');    # $next_comp;

    # the item at the end of the chain
    $last = $comp->last('in');

=head1 DESCRIPTION

C<Net::Proxy;:Node> is a mixin class that provides methods to navigate
along a chain of C<Net::Proxy::Block> and C<Net::Proxy::BlockInstance>
objects used in C<Net::Proxy>.

Both classes inherit from C<Net::Proxy::Node> a default implementation
of the following methods:

=over 4

=item next( $direction )

Return the next item in the chain, following direction C<$direction>
(C<in> or C<out>).

Return C<undef> if there is no next item, or no chain in that direction.

=item set_next( $direction, $item )

Set the next item in the chain, when following direction C<$direction>.

=item last( $direction )

Return the last item at the end of the chain.

Return C<undef> if the current objet is already the last item of
the chain, or if there is no chain in that direction.

Note that the last object in a chain may not be a C<Net::Proxy::Node>
object. It must, however, be a blessed object.

=item act_on( $message, $from, $direction )

Process a message and return zero or more messages, to be forwarded
to the next element in the chain..

=back

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book@cpan.org> >>.

=head1 COPYRIGHT

Copyright 2007-2008 Philippe Bruhat (BooK), All Rights Reserved.
 
=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

