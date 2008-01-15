use strict;
use warnings;
use Test::More;
use Net::Proxy::Message;
use Net::Proxy::MessageQueue;
use Net::Proxy::Component;

my @comps;

package Net::Proxy::Component::test;
use Test::More;

our @ISA = qw( Net::Proxy::Component );
__PACKAGE__->build_factory_class();

sub init {
    my ($self) = @_;
    $self->{name} =~ s/fact/comp/;
    ok( 1, "$self->{name} init()" );
    push @comps, $self;    # keep all created components
}

sub ZLONK {
    my ( $self, $message, $from, $direction ) = @_;
    is( $message->{type}, 'ZLONK',
        "$self->{name} got message ZLONK ($direction)" );
    return;                # stop now
}

sub BAM {
    my ( $self, $message, $from, $direction ) = @_;
    is( $message->{type}, 'BAM',
        "$self->{name} got message BAM ($direction)" );
    return $message;    # pass it on
}

sub KAPOW {
    my ( $self, $message, $from, $direction ) = @_;
    is( $message->{type}, 'KAPOW',
        "$self->{name} got message KAPOW ($direction)" );
    return $message;    # pass it on
}

package Net::Proxy::ComponentFactory::test;
use Test::More;

sub START {
    my ( $self, $message, $from, $direction ) = @_;
    is( $message->{type}, 'START',
        "$self->{name} got message START ($direction)" );
    return $message;    # pass it on
}

sub ONLY {
    my ( $self, $message, $from, $direction ) = @_;
    is( $message->{type}, 'ONLY',
        "$self->{name} got message ONLY ($direction)" );
    return $message;    # pass it on
}

package main;

plan tests => 12 + 6 + 5;

# build a chain of factories
my $fact1 = Net::Proxy::ComponentFactory::test->new( { name => 'fact1' } );
my $fact2 = Net::Proxy::ComponentFactory::test->new( { name => 'fact2' } );
my $fact3 = Net::Proxy::ComponentFactory::test->new( { name => 'fact3' } );
my $fact4 = Net::Proxy::ComponentFactory::test->new( { name => 'fact4' } );

$fact1->set_next( in => $fact2 )->set_next( in => $fact3 );

# Note that the messages will be received in an interleaved manner,
# because new messages are stacked on top of all the others
Net::Proxy::MessageQueue->queue(

    # START the factory chain (and create a component chain)
    # fact1 START, (1)
    # comp1 init,  (2)
    # fact2 START, (8)
    # comp2 init,  (9)
    # fact3 START, (11)
    # comp3 init   (12)
    # => 6 tests
    [ undef, $fact1, 'in', Net::Proxy::Message->new('START') ],

    # processed once (create a chain with a single component)
    # comp1 init, (3)
    # comp1 ZLONK (6)
    # => 2 tests
    [ bless( [], 'Zlonk' ), $fact1, 'in', Net::Proxy::Message->new('ZLONK') ],

    # doesn't create any component
    # fact1 ONLY, (4)
    # fact2 ONLY, (7)
    # fact3 ONLY  (10)
    # => 3 tests
    [   undef, $fact1,
        'in', Net::Proxy::Message->new( ONLY => { factory => 1 } )
    ],

    # fact4 ONLY (5)
    # => 1 test
    [   undef, $fact4,
        'in', Net::Proxy::Message->new( ONLY => { factory => 1 } )
    ],
);

# process all factory messages in the queue
while ( my $ctx = Net::Proxy::MessageQueue->next() ) {
    my ( $from, $to, $direction, $message ) = @$ctx;
    $to->process( $message, $from, $direction );
}

# 12 tests run at this stage

Net::Proxy::MessageQueue->queue(

    # processed by all components, adds a socket at the end
    # comp1 BAM, (13)
    # comp2 BAM, (15)
    # comp3 BAM  (17)
    [ undef, $comps[0], 'in', Net::Proxy::Message->new('BAM') ],

    # processed by all components
    # comp1 KAPOW, (14)
    # comp2 KAPOW, (16)
    # comp3 KAPOW  (18)
    [ undef, $comps[0], 'in', Net::Proxy::Message->new('KAPOW') ],

    # processed by no component (for coverage)
    [ undef, $comps[0], 'in', Net::Proxy::Message->new('ZOWIE') ],
);

# 6 more tests run here

# process all messages in the queue
while ( my $ctx = Net::Proxy::MessageQueue->next() ) {
    my ( $from, $to, $direction, $message ) = @$ctx;
    $to->process( $message, $from, $direction );
}

# a second chain was created...
# it contains a single component, because the fist component dropped
# the message after processing it, so it never reached the second factory
is( @comps, 4, "four components were created" );
{
    my $i = 0;
    for my $name ( (qw( comp1 comp1 comp2 comp3 )) ) {
        is( $comps[$i]{name}, $name, "component $i == $name" );
        $i++;
    }
}

