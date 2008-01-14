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
    croak "Message type '$1' is reserved"
        if $type =~ /^(BEGIN|INIT|(?:UNIT)?CHECK|END
                      |AUTOLOAD|DESTROY|CLONE(?:_SKIP)?)$/x;

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

=item _at_ => $time

Require the message to be delivered B<at> the given time or after.
The time is given in seconds (possibly fractional) since the I<epoch>.

=item _in_ => $delay

Require the message to be delivered B<in> the given delay or after.
The delay is given in seconds (possibly fractional).

=back

These keys are removed from the message when it is added to the queue.

=head2 Reserved names

Because the names are used by Perl, no message can be named C<BEGIN>,
C<CHECK>, C<INIT>, C<UNITCHECK>, C<END>, C<CLONE>, C<CLONE_SKIP>,
C<AUTOLOAD> or C<DESTROY>.

C<< Net::Proxy::Message->new() >> will die if one of those names is used.

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book@cpan.org> >>.

=head1 COPYRIGHT

Copyright 2007-2008 Philippe Bruhat (BooK), All Rights Reserved.
 
=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

