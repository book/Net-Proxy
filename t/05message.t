use strict;
use warnings;
use Test::More;
use List::Util qw(sum);

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

plan tests => sum map { @$_ == 1 ? 3 : 2 } @tests;

for my $test (@tests) {
    my ( $args, $fail ) = @$test;

    my $mesg = eval { Net::Proxy::Message->new(@$args) };

    if ($fail) {
        like( $@, $fail, 'Message creation failed' );
        is( $mesg, undef, 'No message created' );
    }
    else {
        isa_ok( $mesg, 'Net::Proxy::Message' );
        is( $mesg->type, $args->[0]{type}, "of type $args->[0]{type}" );
        is_deeply( $mesg, $args->[0], 'with all the data' );
    }
}
