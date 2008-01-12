use strict;
use warnings;
use Test::More;
use Net::Proxy::Message;
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

sub ONLY {
    my ( $self, $message, $from, $direction ) = @_;
    is( $message->{type}, 'ONLY',
        "$self->{name} got message ONLY ($direction)" );
    return $message;    # pass it on
}


package main;

plan tests => 23;

# build a chain of factories
my $fact1 = Net::Proxy::ComponentFactory::test->new( { name => 'fact1' } );
my $fact2 = Net::Proxy::ComponentFactory::test->new( { name => 'fact2' } );
my $fact3 = Net::Proxy::ComponentFactory::test->new( { name => 'fact3' } );

$fact1->set_next( in => $fact2 )->set_next( in => $fact3 );

# START the factory chain (and create a component chain)
$fact1->process( [ Net::Proxy::Message->new('START') ], undef, 'in' );

# processed once (create a chain with a single component)
$fact1->process( [ Net::Proxy::Message->new('ZLONK') ],
    bless( [], 'Zlonk' ), 'in' );

# doesn't create any component
$fact1->process( [ Net::Proxy::Message->new( ONLY => { factory => 1 } ) ],
    undef, 'in' );

# a second chain was created...
# it contains a single component, because the fist component dropped
# the message after processing it, so it never reached the second factory
is( @comps, 4, "four components were created" );
{
    my $i = 0;
    for my $name ( (qw( comp1 comp2 comp3 comp1 )) ) {
        is( $comps[$i]{name}, $name, "component $i == $name" );
        $i++;
    }
}

# processed by all components, adds a socket at the end
$comps[0]->process( [ Net::Proxy::Message->new('BAM') ], undef, 'in' );

# processed by all components
$comps[0]->process( [ Net::Proxy::Message->new('KAPOW') ], undef, 'in' );

# processed by no component (for coverage)
$comps[0]->process( [ Net::Proxy::Message->new('ZOWIE') ], undef, 'in' );

