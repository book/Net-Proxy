package Net::Proxy::Message;
use strict;
use warnings;
use Carp;

sub new {
    my ( $class, $type, $args ) = @_;
    $args = defined $args ? $args : {};

    croak "Second parameter of new() must be a HASH reference"
        if ref $args ne 'HASH';
    croak "No type given for message"          if !$type;
    croak "Type must be a string, not a $type" if ref $type;

    return bless { %$args, type => $type }, $class;
}

sub type { $_[0]{type} }

1;

__END__

=head1 NAME

Net::Proxy::Message - The message class used by Net::Proxy

=head1 SYNOPSIS

    $message = Net::Proxy::Message->new( 'CAN_READ' );

    $message = Net::Proxy::Message->new( DATA => { data => 'zlonk bam' } );

=head1 DESCRIPTION

C<Net::Proxy::Message> represents a message passed between components of
a proxy chain.

A component can handle a message if it has a method by the same name as
the message type. If a component can't handle a message, it simply
passes it on to the sender's peer (if any).

=head1 METHODS

The C<Net::Proxy::Message> supports the following methods:

=over 4

=item new( $type => { ... } )

This method creates a new C<Net::Proxy::Message> object of type C<$type>.
A message is simply a blessed hash containing a copy of the given arguments.

The signification of the key/value pairs depends on the message.

Special keys that have a global meaning for C<Net::Proxy> or
C<Net::Proxy::MessageQueue> are enclosed between underscores (C<_>).

=item type()

Return the message type.

=back

=head1 MESSAGES

=head2 Special keys

The class C<Net::Proxy::MessageQueue> recognize two special keys in a
message:

=over 4

=item _in_ => $delay

Require the message to be delivered B<in> the given delay or after.
The delay is given in seconds (possibly fractional).

=item _at_ => $time

Require the message to be delivered B<at> the given time or after.
The time is given in seconds (possibly fractional) since the I<epoch>.

=back

These keys are removed from the message when it is added to the queue.


=head2 Messages naming convention

Some messages are generic and recognized by different types of
C<Component> and C<ComponentFactory> objects. Others are very
specific to a type of objects.

The naming convention is the following:

=over 4

=item m_<I<MESSAGE>>

Generic message.

=item I<type>_<I<MESSAGE>>

Message specific to components and factories of type C<type>.

=back


=head1 KNOWN MESSAGES

All message handling subroutines have the following signature:

    my ( $self, $message, $from, $direction ) = @_;

Where

=over 4

=item *

C<$self> is the component (or component factory)

=item *

C<$message> is the message

=item *

C<$from> is the sender. This is often a component or a factory, but also
a socket. When the message is sent by the C<Net::Proxy> infrastructure,
C<$from> is undef.

=item *

C<$direction> is the direction of the message. Any message resulting from
the processing of this message will be send forward in the same direction.

=back


=head2 Generic messages

The following messages are "sent" by a socket (i.e. C<$from> is a
C<IO::Socket> object).

=over 4

=item m_ACCEPT

=item m_CAN_READ

=item m_CAN_WRITE

=item m_HAS_EXCEPTION

=back

The following messages are sent by components or factories.

=over 4

=item m_DATA

=item m_START_CONNECTION

=item m_CONNECTION_CLOSED

=back

The following message is sent by the infrastructure (C<$from> is undef).

=over 4

=item m_START_PROXY

=back

=head2 Specific messages

The following messages are sent/received by specific components or factories:

=over 4

=item dual_TIMEOUT

=back

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book@cpan.org> >>.

=head1 COPYRIGHT

Copyright 2007-2008 Philippe Bruhat (BooK), All Rights Reserved.
 
=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

