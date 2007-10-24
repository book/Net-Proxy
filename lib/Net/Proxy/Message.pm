package Net::Proxy::Message;
use strict;
use warnings;
use Carp;

sub new {
    my ( $class, $type, $args ) = @_;
    $args = defined $args ? $args : {};

    croak "Second parameter of new() must be a HASH reference"
        if ref $args ne 'HASH';
    croak "No type given for message" if !$type;
    croak "Type must be a string, not a $type" if ref $type;

    return bless { %$args, type => $type }, $class;
}

sub type { $_[0]{type} }

1;

__END__

=head1 NAME

Net::Proxy::Message - The message class used by Net::Proxy

=head1 SYNOPSIS

    my $message = Net::Proxy::Message->new( { type => 'CAN_READ' } );

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

=item type()

Return the message type.

=back

=head1 MESSAGES

=head2 Reserved names

Because the names are used by Perl, no message can be named C<BEGIN>,
C<CHECK>, C<INIT>, C<END>, C<AUTOLOAD> or C<DESTROY>.

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book@cpan.org> >>.

=head1 COPYRIGHT

Copyright 2007 Philippe Bruhat (BooK), All Rights Reserved.
 
=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

