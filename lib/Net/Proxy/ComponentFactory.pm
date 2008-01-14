package Net::Proxy::ComponentFactory;

use strict;
use warnings;
use Scalar::Util qw( blessed );

use Net::Proxy::Node;
our @ISA = qw( Net::Proxy::Node );

#
# CLASS METHODS
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

    # let the mixin class process the messages
    my @messages = $self->act_on( $message, $from, $direction );

    # forward factory messages directly to the next factory
    if( my $next = $self->next($direction) ) {
        $self->send_to( $next => $direction, grep { $_->{factory} } @messages );
    }

    # remove factory messages and abort if none left
    @messages = grep { !$_->{factory} } @messages;
    return unless @messages;

    # create a component
    my $class = ref $self;
    $class =~ s/^Net::Proxy::ComponentFactory::/Net::Proxy::Component::/;
    my $comp = $class->new($self);

    # link the component to the rest of the chain
    $from->set_next( $direction => $comp )
        if blessed $from && $from->isa('Net::Proxy::Node');
    $comp->set_next( $direction => $self->next($direction) );

    # forward the message to the new component instance
    $self->send_to( $comp => $direction, @messages );

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
creates an actual C<Net::Proxy::BLockInstance> object, to which it passes the
processed message.

The new component is linked to the next factory in the chain.

=head1 METHODS

This base class provides several methods:

=over 4

=item new( $args )

Return a new C<Net::Proxy::ComponentFactory> object, initialized with the content
of the C<$args> hashref.

=item process( $messages, $from, $direction )

The default processing for a message stack. The messages are processed
by the appropriate method (if any) and then a component is
created, inserted in the chain linked to the actual sockets (in the
proper C<$direction>). The new component then receives the message stack and
processes it.

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book@cpan.org> >>.

=head1 COPYRIGHT

Copyright 2007-2008 Philippe Bruhat (BooK), All Rights Reserved.
 
=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

