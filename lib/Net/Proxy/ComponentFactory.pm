package Net::Proxy::ComponentFactory;

use strict;
use warnings;

use Net::Proxy::Node;
our @ISA = qw( Net::Proxy::Node );

sub new {
    my ( $class, $args ) = @_;
    my $self = bless { %{ $args || {} } }, $class;
    $self->init() if $self->can('init');
    return $self;
}

sub process {
    my ( $self, $message, $from, $direction ) = @_;

    my $action = $message->type();
    if ( $self->can($action) ) {
        $message = $self->$action( $message, $from, $direction );
        $action = $message->type();    # $message might have changed
    }

    # START is passed from factory to factory
    if ( $action eq 'START' ) {
        my $next = $self->next($direction);
        $next->process( $message, $self, $direction )
            if defined $next && $next->isa('Net::Proxy::Node');
        return;
    }

    # ABORT
    return if $action eq 'ABORT';

    # create a component
    my $class = ref $self;
    $class =~ s/^Net::Proxy::ComponentFactory::/Net::Proxy::Component::/;
    my $component = $class->new($self);

    # link the component to the rest of the chain
    $component->set_next( $direction => $self->next($direction) );

    # pass the message on to the new component
    $component->process( $message, $self, $direction );

    return;
}

1;

__END__

=head1 NAME

Net::Proxy::ComponentFactory - Base class for all Component factories

=head1 SYNOPSIS

=head1 DESCRIPTION

The C<Net::Proxy::ComponentFactory> class is the base class for all
component factories.

When a chain is first created, it is actually a chain of factories.
When the first message is passed to the factory, it processes the message,
creates an actual C<Net::Proxy::Component> object, to which it passes the
processed message.

The new component is linked to the next factory in the chain.

=head1 METHODS

This base class provides a single method:

=over 4

=item process( $message, $from )

The default processing for any message. The message is processed by the
appropriate method (if any) and then a concrete component is created,
inserted in the chain linked to the actual sockets. The component then
receives the message.

The C<INIT> message is send to the next factory in the chain, instead
of a concrete component.

=head1 AUTHOR

=cut

