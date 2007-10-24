package Net::Proxy::BlockInstance;

use strict;
use warnings;
use Scalar::Util qw( blessed );

use Net::Proxy::Node;
our @ISA = qw( Net::Proxy::Node );

#
# CLASS METHODS
#

sub new {
    my ( $class, $args ) = @_;
    my $self = bless { %{ $args || {} } }, $class;
    $self->init() if $self->can('init');
    return $self;
}

#
# INSTANCE METHODS
#
sub process {
    my ( $self, $messages, $from, $direction ) = @_;

    # let the mixin class process the messages
    $self->act_on( $messages, $from, $direction );

    # pass the message on to the next node
    my $next = $self->next($direction);
    $next->process( $messages, $self, $direction )
        if blessed $next && $next->isa('Net::Proxy::Node');

    return;
}


1;

__END__

=head1 NAME

Net::Proxy::BlockInstance - A component in a Net::Proxy chain

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

The C<Net::Proxy::BlockInstance> provides the following methods:

=over 4

=item new( $args )

Return a new C<Net::Proxy::BlockInstance> object, initialized with the
content of the C<$args> hashref.

=item process( $message, $from, $direction )

The default processing for a message stack. The message are processed
by the appropriate method (if any) and then the udpated stack is passed
on to the rest of the chain, in the given C<$direction>.

=back

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book@cpan.org> >>.

=head1 COPYRIGHT

Copyright 2007 Philippe Bruhat (BooK), All Rights Reserved.
 
=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

