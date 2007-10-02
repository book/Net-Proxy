use strict;
use warnings;
use Test::More;
use Net::Proxy::Node;

plan tests => 96;

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

# add a non Net::Proxy::Node object at the end of the chain
use IO::Socket;
my $s = IO::Socket->new();
$d->set_next( in => $s );

is( $a->next('in'),  $b,    'a -> b (in)' );
is( $a->next('out'), undef, 'a -> * (out)' );
is( $b->next('in'),  $c,    'b -> c (in)' );
is( $b->next('out'), $a,    'b -> a (out)' );
is( $c->next('in'),  $d,    'c -> d (in)' );
is( $c->next('out'), $b,    'c -> b (out)' );
is( $d->next('in'),  $s,    'd -> s (in)' );
is( $d->next('out'), $c,    'd -> c (out)' );

is( $a->last('in'),  $s,    'a -> ... -> s (in)' );
is( $a->last('out'), undef, 'a -> * (out)' );
is( $b->last('in'),  $s,    'b -> ... -> s (in)' );
is( $b->last('out'), $a,    'b -> * (out)' );
is( $c->last('in'),  $s,    'c -> ... -> s (in)' );
is( $c->last('out'), $a,    'c -> * (out)' );
is( $d->last('in'),  $s,    'd -> s (in)' );
is( $d->last('out'), $a,    'd -> * (out)' );

# add a non object at the end of the chain
my $h = {};
$d->set_next( in => $h );

is( $a->next('in'),  $b,    'a -> b (in)' );
is( $a->next('out'), undef, 'a -> * (out)' );
is( $b->next('in'),  $c,    'b -> c (in)' );
is( $b->next('out'), $a,    'b -> a (out)' );
is( $c->next('in'),  $d,    'c -> d (in)' );
is( $c->next('out'), $b,    'c -> b (out)' );
is( $d->next('in'),  $h,    'd -> h (in)' );
is( $d->next('out'), $c,    'd -> c (out)' );

is( $a->last('in'),  $h,    'a -> ... -> h (in)' );
is( $a->last('out'), undef, 'a -> * (out)' );
is( $b->last('in'),  $h,    'b -> ... -> h (in)' );
is( $b->last('out'), $a,    'b -> * (out)' );
is( $c->last('in'),  $h,    'c -> ... -> h (in)' );
is( $c->last('out'), $a,    'c -> * (out)' );
is( $d->last('in'),  $h,    'd -> s (in)' );
is( $d->last('out'), $a,    'd -> * (out)' );

# remove $c from the chain
$b->set_next( in  => $d );
$d->set_next( out => $b );

is( $a->next('in'),  $b,    'a -> b (in)' );
is( $a->next('out'), undef, 'a -> * (out)' );
is( $b->next('in'),  $d,    'b -> d (in)' );
is( $b->next('out'), $a,    'b -> a (out)' );
is( $c->next('in'),  $d,    'c -> d (in)' );     # not a bug
is( $c->next('out'), $b,    'c -> b (out)' );    # not a bug
is( $d->next('in'),  $h,    'd -> h (in)' );
is( $d->next('out'), $b,    'd -> b (out)' );

is( $a->last('in'),  $h,    'a -> ... -> h (in)' );
is( $a->last('out'), undef, 'a -> * (out)' );
is( $b->last('in'),  $h,    'b -> ... -> h (in)' );
is( $b->last('out'), $a,    'b -> * (out)' );
is( $c->last('in'),  $h,    'c -> ... -> h (in)' );    # not a bug
is( $c->last('out'), $a,    'c -> * (out)' );          # not a bug
is( $d->last('in'),  $h,    'd -> h (in)' );
is( $d->last('out'), $a,    'd -> * (out)' );

