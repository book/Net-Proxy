package Net::Proxy::BlockInstance;

use strict;
use warnings;
use Scalar::Util qw( blessed );

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

