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
    $self->{buffer} = $data; # keep what's left for next time

    return @messages;
}

1;

__END__

=head1 NAME

Net::Proxy::Component::line - Line buffering component

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

The C<Net::Proxy::Component::line> handles the following messages:

=over 4

=item DATA

=back

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book@cpan.org> >>.

=head1 COPYRIGHT

Copyright 2008 Philippe Bruhat (BooK), All Rights Reserved.
 
=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

