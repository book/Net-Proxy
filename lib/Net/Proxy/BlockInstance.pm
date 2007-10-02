package Net::Proxy::BlockInstance;

use strict;
use warnings;

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
    my ( $self, $message, $from, $direction ) = @_;

    my $action = $message->type();
    if ( $self->can($action) ) {
        $message = $self->$action( $message, $from, $direction );
        $action = $message->type();    # $message might have changed
    }

    # ABORT
    return if $action eq 'ABORT';

    # pass the message on to the next node
    my $next = $self->next($direction);
    $next->process( $message, $self, $direction )
        if defined $next && $next->isa('Net::Proxy::Node');

    return;
}

1;

__END__

=head1 NAME

Net::Proxy::BlockInstance - A component in a Net::Proxy chain

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book@cpan.org> >>.

=head1 COPYRIGHT

Copyright 2007 Philippe Bruhat (BooK), All Rights Reserved.
 
=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

