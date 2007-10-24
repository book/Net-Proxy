use strict;
use warnings;
use Test::More;

plan tests => 2;

use_ok( 'Net::Proxy::Component' );

my $c = Net::Proxy::Component->new();
isa_ok( $c, 'Net::Proxy::Component' );

