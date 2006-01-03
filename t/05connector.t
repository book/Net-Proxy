use Test::More tests => 6;
use strict;
use warnings;

use Net::Proxy::Connector;

my $c1 = Net::Proxy::Connector->new( {} );
my $c2 = Net::Proxy::Connector->new( {} );
my $s1 = []; # array ref instead of socket
my $s2 = [];
my $s3 = [];

$c1->register_as_manager_of( $s1 );
$c2->register_as_manager_of( $s2 );
$c2->register_as_manager_of( $s3 );

# MANAGERS

# class method
is( $c1, Net::Proxy::Connector->manager_of( $s1 ), "c1 manages s1" );

# instance method (not very useful)
is( $c2, $c2->manager_of( $s2 ), "c2 manages s2" );
is( $c2, $c1->manager_of( $s3 ), "c2 manages s3" );

# PEERS
eval { $c1->set_peer( $s1 ); };
like( $@, qr/is not a Net::Proxy::Connector object/, 'peer should be a NPC');

$c1->set_peer( $c2 );
is( $c1->get_peer(), $c2, "c2 is the peer of c1" );
is( $c2->get_peer(), $c1, "c1 is the peer of c2" );
