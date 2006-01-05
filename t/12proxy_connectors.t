use strict;
use warnings;
use Test::More tests => 1;
use Net::Proxy;

my $proxy = Net::Proxy->new({
    in => { type => 'dummy' },
    out => { type => 'dummy' },
});

isnt( $proxy->in_connector(), $proxy->out_connector(), 'Distinct connectors' );
