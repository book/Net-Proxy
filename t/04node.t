use strict;
use warnings;
use Test::More;
use Net::Proxy::Node;

plan tests => 48;

my $a = bless {}, 'Net::Proxy::Node';
my $b = bless {}, 'Net::Proxy::Node';
my $c = bless {}, 'Net::Proxy::Node';
my $d = bless {}, 'Net::Proxy::Node';

# no chain yet
is( $a->next('in'),  undef, 'a -> * (in)' );
is( $a->next('out'), undef, 'a -> * (out)' );
is( $b->next('in'),  undef, 'b -> * (in)' );
is( $b->next('out'), undef, 'b -> * (out)' );
is( $c->next('in'),  undef, 'c -> * (in)' );
is( $c->next('out'), undef, 'c -> * (out)' );
is( $d->next('in'),  undef, 'd -> * (in)' );
is( $d->next('out'), undef, 'd -> * (out)' );

is( $a->last('in'),  undef, 'a -> * (in)' );
is( $a->last('out'), undef, 'a -> * (out)' );
is( $b->last('in'),  undef, 'b -> * (in)' );
is( $b->last('out'), undef, 'b -> * (out)' );
is( $c->last('in'),  undef, 'c -> * (in)' );
is( $c->last('out'), undef, 'c -> * (out)' );
is( $d->last('in'),  undef, 'd -> * (in)' );
is( $d->last('out'), undef, 'd -> * (out)' );

# direction: in
$a->set_next( in => $b );
$b->set_next( in => $c );
$c->set_next( in => $d );

is( $a->next('in'),  $b,    'a -> b (in)' );
is( $a->next('out'), undef, 'a -> * (out)' );
is( $b->next('in'),  $c,    'b -> c (in)' );
is( $b->next('out'), undef, 'b -> * (out)' );
is( $c->next('in'),  $d,    'c -> d (in)' );
is( $c->next('out'), undef, 'c -> * (out)' );
is( $d->next('in'),  undef, 'd -> * (in)' );
is( $d->next('out'), undef, 'd -> * (out)' );

is( $a->last('in'),  $d,    'a -> ... -> d (in)' );
is( $a->last('out'), undef, 'a -> * (out)' );
is( $b->last('in'),  $d,    'b -> ... -> d (in)' );
is( $b->last('out'), undef, 'b -> * (out)' );
is( $c->last('in'),  $d,    'c -> ... -> d (in)' );
is( $c->last('out'), undef, 'c -> * (out)' );
is( $d->last('in'),  undef, 'd -> * (in)' );
is( $d->last('out'), undef, 'd -> * (out)' );

# direction: out
$d->set_next( out => $c );
$c->set_next( out => $b );
$b->set_next( out => $a );

is( $a->next('in'),  $b,    'a -> b (in)' );
is( $a->next('out'), undef, 'a -> * (out)' );
is( $b->next('in'),  $c,    'b -> c (in)' );
is( $b->next('out'), $a,    'b -> a (out)' );
is( $c->next('in'),  $d,    'c -> d (in)' );
is( $c->next('out'), $b,    'c -> b (out)' );
is( $d->next('in'),  undef, 'd -> * (in)' );
is( $d->next('out'), $c,    'd -> c (out)' );

is( $a->last('in'),  $d,    'a -> ... -> d (in)' );
is( $a->last('out'), undef, 'a -> * (out)' );
is( $b->last('in'),  $d,    'b -> ... -> d (in)' );
is( $b->last('out'), $a,    'b -> * (out)' );
is( $c->last('in'),  $d,    'c -> ... -> d (in)' );
is( $c->last('out'), $a,    'c -> * (out)' );
is( $d->last('in'),  undef, 'd -> * (in)' );
is( $d->last('out'), $a,    'd -> * (out)' );
