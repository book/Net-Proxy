use Test::More;
use strict;
use warnings;
use Net::Proxy;

# a dummy component class
package Net::Proxy::ComponentFactory::dummy;
use Net::Proxy::ComponentFactory;
our @ISA = qw( Net::Proxy::ComponentFactory );
$INC{'Net/Proxy/Component/dummy.pm'} = 1;

package main;

# OK stuff
my @ok_tests = (

    # empty chain
    [ [], undef, 'no component' ],

    # single component
    [   [ { type => 'dummy' } ],
        Net::Proxy::ComponentFactory::dummy->new( { type => 'dummy' } ),
        'one component'
    ],

    # two components
    [   [   { type => 'dummy', zlonk => 'bam' },
            { type => 'dummy', clunk => 'kayo' },
        ],
        do {
            my $f1 = Net::Proxy::ComponentFactory::dummy->new(
                { type => 'dummy', zlonk => 'bam' } );
            my $f2 = Net::Proxy::ComponentFactory::dummy->new(
                { type => 'dummy', clunk => 'kayo' } );
            $f1->set_next( in  => $f2 );
            $f2->set_next( out => $f1 );
            $f1;
        },
        'two components'
    ],

    # three components
    [   [   { type => 'dummy', zlonk => 'bam' },
            { type => 'dummy', clunk => 'kayo' },
            { type => 'dummy', zok   => 'crash' },
        ],
        do {
            my $f1 = Net::Proxy::ComponentFactory::dummy->new(
                { type => 'dummy', zlonk => 'bam' } );
            my $f2 = Net::Proxy::ComponentFactory::dummy->new(
                { type => 'dummy', clunk => 'kayo' } );
            my $f3 = Net::Proxy::ComponentFactory::dummy->new(
                { type => 'dummy', zok => 'crash' } );
            $f1->set_next( in  => $f2 );
            $f2->set_next( in  => $f3 );
            $f3->set_next( out => $f2 );
            $f2->set_next( out => $f1 );
            $f1;
        },
        'three components'
    ],
);

my @nok_tests = (
    [   [ [] ], qr/^All chain\(\) parameters must be HASHREF/, 'ARRAYREF args'
    ],
    [   [ {} ], qr/^'type' key required for component 1/, 'no type for comp 1'
    ],
    [   [ { type => 'dummy' }, {} ],
        qr/^'type' key required for component 2/,
        'no type for comp 2'
    ],
    [   [ { type => 'zlonk' } ],
        qr/^Couldn't load Net::Proxy::Component::zlonk for component 1 \(zlonk\): /,
        'component zlonk'
    ],
);

plan tests => 2 * @ok_tests + @nok_tests;

# test constructor

my $chain;
for my $test (@ok_tests) {
    my ( $args, $result, $desc ) = @$test;

    eval { $chain = Net::Proxy->chain(@$args); };
    is( $@, '', "no error with $desc" );
    is_deeply( $chain, $result, "expected result with $desc" );
}

for my $test (@nok_tests) {
    my ( $args, $re, $desc ) = @$test;

    eval { $chain = Net::Proxy->chain(@$args); };
    like( $@, $re, "failed: $desc" );
}

