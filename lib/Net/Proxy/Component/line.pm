package Net::Proxy::Component::line;

use strict;
use warnings;

use Net::Proxy::Component;
our @ISA = qw( Net::Proxy::Component );
__PACKAGE__->build_factory_class();

use Net::Proxy::Message;

sub init { $_[0]{buffer} = '' }

#
# Messages
#
sub DATA {
    my ( $self, $message, $from, $direction ) = @_;
    my @messages;

    my $data = $self->{buffer} . $message->{data};
    while ( $data =~ s/(.*?(?:\015\012?|\012\015?))// ) {
        push @messages, Net::Proxy::Message->new( DATA => { data => $1 } );
    }
    $self->{buffer} = $data;    # keep what's left for next time

    return @messages;
}

1;

__END__

=head1 NAME

Net::Proxy::Component::line - Line buffering component

=head1 SYNOPSIS

=head1 DESCRIPTION

C<Net::Proxy::Component::line> is a component that turns a random
data stream into a stream of lines.

=head1 MESSAGES

The C<Net::Proxy::Component::line> handles the following messages:

=over 4

=item DATA

A C<DATA> message is split in several C<DATA> messages (ending with
either C<CR>, C<LF>, C<CR-LF> or C<LF-CR>).

If it doesn't end with a newline, the last chunk of data in the message
will be kept and prepended to the content of the next C<DATA> message.
B<Warning:> if used on a binary stream, this component can lead to huge
memory consumption.

=back

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book@cpan.org> >>.

=head1 COPYRIGHT

Copyright 2008 Philippe Bruhat (BooK), All Rights Reserved.
 
=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

