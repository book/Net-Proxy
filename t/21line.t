use strict;
use warnings;
use Test::More;

use Net::Proxy::Component::line;

my @tests = (

    # no data
    [ '', [] ],

    # simple one-liners
    [ "single line\n",    ["single line\n"] ],
    [ "one line\012",     ["one line\012"] ],
    [ "one line\015",     ["one line\015"] ],
    [ "one line\015\012", ["one line\015\012"] ],
    [ "one line\012\015", ["one line\012\015"] ],

    # basic two-liner
    [ << 'EOD', [ "line 1\n", "line 2\n" ] ],
line 1
line 2
EOD

    # buffering
    [ "one line\nsome data", ["one line\n"] ],
    [   " left to write\nand some more\n",
        [ "some data left to write\n", "and some more\n" ]
    ],
);

plan tests => 2 * @tests;
my $comp = Net::Proxy::Component::line->new();

for my $test (@tests) {
    my ( $data_in, $data_out ) = @$test;

    my $msg_in
        = Net::Proxy::Message->new( m_DATA => { data => $data_in } );
    my @msgs_out = $comp->act_on( $msg_in, undef, 'in' );

    is( @msgs_out, @$data_out, 'Got ' . @$data_out . ' messages out' );
    is_deeply( [ map { $_->{data} } @msgs_out ],
        $data_out, 'Expected content for messages' );

}

