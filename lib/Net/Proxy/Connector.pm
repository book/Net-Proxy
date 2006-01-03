package Net::Proxy::Connector;
use strict;
use warnings;
use Carp;
use Scalar::Util qw( refaddr );

# private class data
my %MANAGER_OF;
my %PEER_OF;

sub debug {
    use Data::Dumper;
    print Data::Dumper->Dump( [\%MANAGER_OF, \%PEER_OF], [qw(*MANAGER_OF *PEER_OF )] );
}
#
# the most basic constructor possible
#
sub new {
    my ( $class, $args ) = @_;
    return bless {%$args}, $class;
}

#
# link NPP objects and sockets
#
sub register_as_manager_of {
    my ( $self, $sock ) = @_;
    $MANAGER_OF{ refaddr $sock} = $self;
    return;
}

sub manager_of { return $MANAGER_OF{ refaddr $_[1] }; }

#
#link NPP objects together
#
sub set_peer {
    my ( $self, $peer ) = @_;

    croak "$peer is not a Net::Proxy::Connector object"
        if !UNIVERSAL::isa( $peer, 'Net::Proxy::Connector' );

    # set each one as the peer of the other
    $PEER_OF{ refaddr $self} = $peer;
    $PEER_OF{ refaddr $peer} = $self;
}

sub get_peer { return $PEER_OF{ refaddr $_[0] }; }

1;

__END__

=head1 NAME

Net::Proxy::Connector - Base class for Net::Proxy protocols

=head1 SYNOPSIS

    package Net::Proxy::Connector::zlonk;

    use strict;
    our @ISA = qw( Net::Proxy::Connector );

    # if it can be used as an 'in' connector
    sub listen { }
    sub accept_from { }

    # if it can be used as an 'out' connector
    sub open_connection { }

    1;

=head1 DESCRIPTION

C<Net::Proxy::Connector> is the base class for all specialised
protocols used by C<Net::Proxy>.

=head1 METHODS

=head2 Class methods

The base class provides the following methods:

=over 4

=item new()

=item manager_of( $sock )

=back

=head2 Instance methods

=over 4

=item register_as_manager_of( $sock )

=item set_peer( $proto )

=item get_peer()

=back

=head1 AUTHOR

=head1 COPYRIGHT

=head1 LICENSE

