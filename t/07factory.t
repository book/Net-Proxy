use strict;
use warnings;
use Test::More;

plan tests => 2;

use_ok( 'Net::Proxy::ComponentFactory' );

my $c = Net::Proxy::ComponentFactory->new();
isa_ok( $c, 'Net::Proxy::ComponentFactory' );

