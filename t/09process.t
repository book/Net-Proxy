use strict;
use warnings;
use Test::More;
use Net::Proxy::Message;
use Net::Proxy::Component;

my $start;

package Net::Proxy::Component::test;
use Test::More;

our @ISA = qw( Net::Proxy::Component );
__PACKAGE__->build_factory_class();

sub init {
    my ($self) = @_;
    $self->{name} =~ s/fact/comp/;
    ok( 1, "$self->{name} init()" );
    $start ||= $self;    # keep a link to the first component
}

sub ZLONK {
    my ( $self, $message, $from, $direction ) = @_;
    is( $message->{type}, 'ZLONK',
        "$self->{name} got message ZLONK ($direction)" );
    return;              # stop now
}

sub BAM {
    my ( $self, $message, $from, $direction ) = @_;
    is( $message->{type}, 'BAM',
        "$self->{name} got message BAM ($direction)" );
    if ( !$self->next($direction) ) {

        # we're last, let's add a socket to the end
        use IO::Socket;
        $self->set_next( in => IO::Socket->new() );
        ok( $self->next('in'), 'Created a socket' );
    }
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

package main;

plan tests => 14;

# build a chain of factories
my $fact1 = Net::Proxy::ComponentFactory::test->new( { name => 'fact1' } );
my $fact2 = Net::Proxy::ComponentFactory::test->new( { name => 'fact2' } );
my $fact3 = Net::Proxy::ComponentFactory::test->new( { name => 'fact3' } );

$fact1->set_next( in => $fact2 )->set_next( in => $fact3 );

# START the factory chain
$fact1->process( [ Net::Proxy::Message->new( { type => 'START' } ) ],
    undef, 'in' );

# processed once
$fact1->process( [ Net::Proxy::Message->new( { type => 'ZLONK' } ) ],
    bless( [], 'Zlonk' ), 'in' );

# processed by all components, adds a socket at the end
$start->process( [ Net::Proxy::Message->new( { type => 'BAM' } ) ],
    undef, 'in' );

# processed by all components
$start->process( [ Net::Proxy::Message->new( { type => 'KAPOW' } ) ],
    undef, 'in' );

# processed by no component (for coverage)
$start->process( [ Net::Proxy::Message->new( { type => 'ZOWIE' } ) ],
    undef, 'in' );

