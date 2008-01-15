package Net::Proxy::Component;

use strict;
use warnings;
use Scalar::Util qw( blessed );

use Net::Proxy::Node;
our @ISA = qw( Net::Proxy::Node );

#
# CLASS METHODS
#

sub build_factory_class {
    my ($class) = @_;
    my ($component) = $class =~ m/^Net::Proxy::Component::(.*)$/;

    # eval the factory building code
    eval << "FACTORY";
    package Net::Proxy::ComponentFactory::$component;
    use Net::Proxy::ComponentFactory;
    our \@ISA = qw( Net::Proxy::ComponentFactory );
FACTORY

    #die $@ if $@; # can't happen. Uncomment when changing the above code

    return;
}

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

    # let the mixin class process the messages
    my @messages = $self->act_on( $message, $from, $direction );

    # forward the messages to the next node
    if ( my $next = $self->next($direction) ) {
        $self->send_to( $next => $direction, @messages );
    }

    return;
}

1;

__END__

=head1 NAME

Net::Proxy::Component - A component in a Net::Proxy chain

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

The C<Net::Proxy::Component> provides the following methods:

=over 4

=item build_factory_class()

This method automatically intialize the corresponding C<ComponentFactory>
associated with the C<Component> class. This simplifies the writing of
C<ComponentFactory>/C<Component> classes, and allows the author to have
a single F<.pm> file (for the component) where message-handling methods
are stored for both classes.

=item new( $args )

Return a new C<Net::Proxy::Component> object, initialized with the
content of the C<$args> hashref.

=item process( $messages, $from, $direction )

The default processing for a message. The message is processed
by the appropriate method (if any) and the resulting messages are
forwarded to the rest of the chain, in the given C<$direction>.

=back

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book@cpan.org> >>.

=head1 COPYRIGHT

Copyright 2007-2008 Philippe Bruhat (BooK), All Rights Reserved.
 
=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

