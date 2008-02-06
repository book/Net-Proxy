use strict;
use warnings;
use Test::More;
use List::Util qw(sum);

use Net::Proxy::Message;

my @tests = (
    [ [], qr/^No type given for message / ],
    [ [''], qr/^No type given for message / ],
    [   [ ZLONK => '' ],
        qr/^Second parameter of new\(\) must be a HASH reference/
    ],
    [   [ ZLONK => 'BAM' ],
        qr/^Second parameter of new\(\) must be a HASH reference/
    ],
    [ [ '' => {} ], qr/^No type given for message / ],
    [ [ [] => {} ], qr/^Type must be a string, not a ARRAY/ ],
    [ ['START'] ],
    [ [ 'START' => undef ] ],
    [   [ 'START' => '' ],
        qr/^Second parameter of new\(\) must be a HASH reference/
    ],
    [ [ START => { type => 'START' } ] ],
    [ [ CAN_READ => {}, 'zlonk' ] ],
    [ [ SET_TIMEOUT => { in => 1.5 } ] ],
);

plan tests => sum map { @$_ == 1 ? 3 : 2 } @tests;

for my $test (@tests) {
    my ( $args, $fail ) = @$test;

    my $mesg = eval { Net::Proxy::Message->new(@$args) };

    if ($fail) {
        ( my $msg = $@ ) =~ s/ at .*//s;
        like( $@, $fail, "Message creation failed: $msg" );
        is( $mesg, undef, 'No message created' );
    }
    else {
        isa_ok( $mesg, 'Net::Proxy::Message' );
        is( $mesg->type, $args->[0], "  of type $args->[0]" );
        is_deeply(
            $mesg,
            { %{ $args->[1] || {} }, type => $args->[0] },
            '  with all the data'
        );
    }
}
