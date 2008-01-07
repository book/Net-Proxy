use strict;
use warnings;
use Test::More;
use Net::Proxy::Message;
use Net::Proxy::Component;

my $first;

package Net::Proxy::Component::test;
use Test::More;

our @ISA = qw( Net::Proxy::Component );
__PACKAGE__->build_factory_class();

sub init {
    my ($self) = shift;
    $self->{name} =~ s/fact/comp/;
    $first ||= $self;    # keep the first component created
}

sub KAPOW {
    my ( $self, $message, $from, $direction ) = @_;
    is( $message->{type}, 'KAPOW',
        "$self->{name} got message KAPOW ($direction)" );
    return $message;     # pass it on
}

package Net::Proxy::ComponentFactory::test;
use Test::More;

package main;

plan tests => 5;

# build a chain of factories
my $fact1 = Net::Proxy::ComponentFactory::test->new( { name => 'fact1' } );
my $fact2 = Net::Proxy::ComponentFactory::test->new(
    { name => 'fact2', only => 'out' } );
my $fact3 = Net::Proxy::ComponentFactory::test->new( { name => 'fact3' } );

# bidirectional chain
$fact1->set_next( in  => $fact2 )->set_next( in  => $fact3 );
$fact3->set_next( out => $fact2 )->set_next( out => $fact1 );

# create the component chain by passing a message to the factory chain
$fact1->process( [ Net::Proxy::Message->new('ZLONK') ], undef, 'in' );

# find the last component in the chain
my $last = $first->last('in');

# processed by all components, but comp2
$first->process( [ Net::Proxy::Message->new('KAPOW') ], undef, 'in' );

# processed by all components
$last->process( [ Net::Proxy::Message->new('KAPOW') ], undef, 'out' );

