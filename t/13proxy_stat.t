use Test::More tests => 6;
use Net::Proxy;

my $proxy = Net::Proxy->new(
    {   in  => { type => 'dummy' },
        out => { type => 'dummy' }
    }
);

is( $proxy->stat_opened(), 0, "No opened connection" );
is( $proxy->stat_closed(), 0, "No closed connection" );

$proxy->stat_inc_opened();
is( $proxy->stat_opened(), 1, "1 opened connection" );
$proxy->stat_inc_opened();
$proxy->stat_inc_opened();
is( $proxy->stat_opened(), 3, "3 opened connections" );

$proxy->stat_inc_closed();
is( $proxy->stat_closed(), 1, "1 closed connection" );
$proxy->stat_inc_closed();
$proxy->stat_inc_closed();
is( $proxy->stat_opened(), 3, "3 closed connections" );
