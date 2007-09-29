use strict;
use warnings;
use Test::More;
use Net::Proxy::Link;

plan tests => 22;

my $X = bless {}, 'Net::Proxy::Link';
my $a = bless {}, 'Net::Proxy::Link';
my $b = bless {}, 'Net::Proxy::Link';
my $c = bless {}, 'Net::Proxy::Link';
my $d = bless {}, 'Net::Proxy::Link';

is( $X->peer_of($a), undef, 'a has no peer' );
is( $X->peer_of($b), undef, 'b has no peer' );
is( $X->peer_of($c), undef, 'c has no peer' );

$X->set_peers( $a, $a );
is( $X->peer_of($a), undef, 'a has no peer' );
is( $X->peer_of(undef), undef, '* has no peer' );

$X->set_peers($a);
is( $X->peer_of($a), undef, 'a has no peer' );
is( $X->peer_of(undef), $a, '* -> X -> a' );

$X->set_peers( undef, $b );
is( $X->peer_of(undef), $b, '* -> X -> b' );
is( $X->peer_of($b), undef, 'b has no peer' );

$X->set_peers( $a, $b );

is( $X->peer_of($a), $b,    'a -> X -> b' );
is( $X->peer_of($b), $a,    'b -> X -> a' );
is( $X->peer_of($c), undef, 'c has no peer' );

$X->set_peers( $a, $c );

is( $X->peer_of($a), $c, 'a -> X -> c' );
is( $X->peer_of($b), $a, 'b -> X -> a' );
is( $X->peer_of($c), $a, 'c -> X -> a' );

$X->delete_peer_of($b);

is( $X->peer_of($a), $c,    'a -> X -> c' );
is( $X->peer_of($b), undef, 'b has no peer' );
is( $X->peer_of($c), $a,    'c -> X -> a' );

$X->remove_from_chain();
is( $a->peer_of(undef), $c, '* -> a -> c' );
is( $c->peer_of(undef), $a, '* -> c -> a' );

$a->remove_from_chain();
is( $c->peer_of(undef), undef, '* -> c -> *' );

$X->set_peers( $a, $b );
$b->set_peers( $X, $c );
$c->set_peers( $b, $d );
my $i = 0;    # sentinel
my ( $from, $comp ) = ( $a, $X );
( $from, $comp ) = ( $comp, $comp->peer_of($from) ) while $comp && $i++ < 8;
is( $from, $d, 'a -> ... -> d' );
