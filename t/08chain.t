use strict;
use warnings;
use Test::More;
use Net::Proxy::Message;
use Net::Proxy::Component;

my $start;

package Net::Proxy::Component::test;

our @ISA = qw( Net::Proxy::Component );
__PACKAGE__->build_factory_class();

package Net::Proxy::ComponentFactory::test;
use Test::More;

sub init {
    my ($self) = @_;
    $self->{name} ||= '<unnamed>';
    ok( 1, "$self->{name}->init() called" );
}

sub START {
    my ( $self, $message, $from, $direction ) = @_;
    is( $message->{type}, 'START',
        "$self->{name} got message START ($direction)" );
    return $message;    # pass it on
}

sub ZLONK {
    my ( $self, $message, $from, $direction ) = @_;
    is( $message->{type}, 'ZLONK',
        "$self->{name} got message ZLONK ($direction)" );
    return;             # stop now
}

package main;

plan tests => 6;

# build a chain of factories
my $fact1 = Net::Proxy::ComponentFactory::test->new( { name => 'fact1' } );
my $fact2 = Net::Proxy::ComponentFactory::test->new();

$fact1->set_next( in => $fact2 )->set_next( in => { bam => 'kapow' } );

# START the factory chain
$fact1->process( Net::Proxy::Message->new('START'), undef, 'in' );

$fact1->process( Net::Proxy::Message->new('ZLONK'), undef, 'in' );

# there is one message (START) waiting in the queue
my @msgs;
push @msgs, $_ while $_ = Net::Proxy::MessageQueue->next;
is( @msgs, 1, '1 context left in the queue' );

# $ctx = [ $from, $to, $direction, $message ]
is( $msgs[0][3]->type, 'START', 'It contains a START message' );

