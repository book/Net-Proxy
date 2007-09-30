use strict;
use warnings;
use Test::More;

use Net::Proxy::Message;

my @tests = (
    [ [], qr/^First parameter of new\(\) must be a HASH reference/ ],
    [ [undef], qr/^First parameter of new\(\) must be a HASH reference/ ],
    [ ['zlonk'], qr/^First parameter of new\(\) must be a HASH reference/ ],
    [ [ {} ], qr/^No type given for message / ],
    [ [ { type => 'START' } ] ],
    [ [ { type => 'CAN_READ' }, 'zlonk' ] ],
    [ [ { type => 'SET_TIMEOUT', in => 1.5 } ] ],
);

plan tests => 2 * @tests;

for my $test (@tests) {
    my ( $args, $fail ) = @$test;

    my $mesg = eval { Net::Proxy::Message->new(@$args) };

    if ($fail) {
        like( $@, $fail, 'Message creation failed' );
        is( $mesg, undef, 'No message created' );
    }
    else {
        isa_ok( $mesg, 'Net::Proxy::Message', "$args->[0]{type} message" );
        is_deeply( $mesg, $args->[0],
            "$args->[0]{type} message has all the data" );
    }
}
