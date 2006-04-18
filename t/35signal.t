use Test::More;
use strict;
use warnings;
use IO::Socket::INET;
use Net::Proxy;

# fetch signal numbers
use Config;
my %sig_num;
my @names = split ' ', $Config{sig_name};
@sig_num{@names} = split ' ', $Config{sig_num};


my $tests = 1;
if( $^O eq 'MSWin32' ) {
    plan skip_all => 'Test irrelevant on MSWin32';
}
else {
    plan tests => $tests;
}

my $pid = fork;

SKIP: {
    skip "fork failed", $tests if !defined $pid;
    if ( $pid == 0 ) {

        # the child process runs the proxy
        my $proxy = Net::Proxy->new(
            {   in  => { type => 'dummy', },
                out => { type => 'dummy', },
            }
        );

        $proxy->register();

        Net::Proxy->mainloop(1);
        exit;
    }
    else {

        # wait for the proxy to set up
        sleep 1;

        kill $sig_num{HUP}, $pid;
        is( wait, $pid, 'Proxy stopped by signal' );
    }
}
