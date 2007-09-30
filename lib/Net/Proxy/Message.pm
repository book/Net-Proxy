package Net::Proxy::Message;
use strict;
use warnings;
use Carp;

sub new {
    my ( $class, $args ) = @_;

    croak "First parameter of new() must be a HASH reference"
        if !defined $args || ref $args ne 'HASH';
    croak 'No type given for message' if !exists $args->{type};

    return bless {%$args}, $class;
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

=item new( { ... } )

This method creates a new C<Net::Proxy::Message> object, which is
simply a bless hash containing a copy of the 

The only key that MUST be present at the message creation is the key
C<type> which defines the type of the message. The message creation
will fail if this key is not present.

=item type()

Return the message type.

=back

=head1 MESSAGES

=head2 Reserved names

Because the names are used by Perl, no message can be named C<BEGIN>,
C<CHECK>, C<INIT>, C<END> or C<AUTOLOAD>.

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book@cpan.org> >>.

=head1 COPYRIGHT

Copyright 2007 Philippe Bruhat (BooK), All Rights Reserved.
 
=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

