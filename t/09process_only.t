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
    ok( 1, "$self->{name} init()" );
    $first ||= $self;    # keep the first component created
}

sub KAPOW {
    my ( $self, $message, $from, $direction ) = @_;
    is( $message->{type}, 'KAPOW',
        "$self->{name} got message KAPOW ($direction)" );
    return $message;     # pass it on
}

sub ZLONK {
    my ( $self, $message, $from, $direction ) = @_;
    is( $message->{type}, 'ZLONK',
        "$self->{name} got message ZLONK ($direction)" );
    return $message;     # pass it on
}

package Net::Proxy::ComponentFactory::test;
use Test::More;

sub ZLONK {
    my ( $self, $message, $from, $direction ) = @_;
    is( $message->{type}, 'ZLONK',
        "$self->{name} got message ZLONK ($direction)" );
    return $message;     # pass it on
}

sub KAPOW {
    my ( $self, $message, $from, $direction ) = @_;
    is( $message->{type}, 'KAPOW',
       "$self->{name} got message KAPOW ($direction)" );
    return $message;     # pass it on
}

package main;

plan tests => 7 + 3;

# build a chain of factories
my $fact1 = Net::Proxy::ComponentFactory::test->new( { name => 'fact1' } );
my $fact2 = Net::Proxy::ComponentFactory::test->new(
    { name => 'fact2', only => 'out' } );
my $fact3 = Net::Proxy::ComponentFactory::test->new( { name => 'fact3' } );

# bidirectional chain
$fact1->set_next( in  => $fact2 )->set_next( in  => $fact3 );
$fact3->set_next( out => $fact2 )->set_next( out => $fact1 );

# create the component chain by passing a message to the factory chain
Net::Proxy::MessageQueue->queue(
    # fact1 ZLONK (1)
    # comp1 init  (2)
    # comp1 ZLONK (3)
    # comp2 init  (4)
    # fact3 ZLONK (5)
    # comp3 init  (6)
    # comp3 ZLONK (7)
    [ undef, $fact1, 'in', Net::Proxy::Message->new('ZLONK') ],
);

# process all factory messages in the queue
while ( my $ctx = Net::Proxy::MessageQueue->next() ) {
    my ( $from, $to, $direction, $message ) = @$ctx;
    $to->process( $message, $from, $direction );
}
 
# 7 messages processed so far

# find the last component in the chain
my $last = $first->last('in');

# create the component chain by passing a message to the factory chain
Net::Proxy::MessageQueue->queue(

    # processed by all components
    # comp3 KAPOW (8)
    # comp2 KAPOW (9)
    # comp1 KAPOW (10)
    [ undef, $last, 'out', Net::Proxy::Message->new('KAPOW') ],
);

# process all factory messages in the queue
while ( my $ctx = Net::Proxy::MessageQueue->next() ) {
    my ( $from, $to, $direction, $message ) = @$ctx;
    $to->process( $message, $from, $direction );
}

# 3 more messages processed

