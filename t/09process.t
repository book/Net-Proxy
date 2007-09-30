use strict;
use warnings;
use Test::More;
use Net::Proxy::Message;
use Net::Proxy::Component;

package Net::Proxy::Component::test;
use Test::More;

our @ISA = qw( Net::Proxy::Component );
__PACKAGE__->build_factory_class();

sub ZLONK {
    my ( $self, $message, $direction ) = @_;
    is( $message->{type}, 'ZLONK',
        "$self->{name} got message ZLONK ($direction)" );
    return Net::Proxy::Message->new( { type => 'ABORT' } );
}

sub KAPOW {
    my ( $self, $message, $direction ) = @_;
    is( $message->{type}, 'KAPOW',
        "$self->{name} got message KAPOW ($direction)" );
    return $message;    # pass it on
}

package main;

plan tests => 4;

# build a chain
my $comp1 = Net::Proxy::Component::test->new( { name => 'comp1' } );
my $comp2 = Net::Proxy::Component::test->new( { name => 'comp2' } );
my $comp3 = Net::Proxy::Component::test->new( { name => 'comp3' } );

$comp1->set_next( in  => $comp2 )->set_next( in  => $comp3 );
$comp3->set_next( out => $comp2 )->set_next( out => $comp1 );

# processed once
$comp1->process( Net::Proxy::Message->new( { type => 'ZLONK' } ) => 'in' );

# process by all components
$comp3->process( Net::Proxy::Message->new( { type => 'KAPOW' } ) => 'out' );

