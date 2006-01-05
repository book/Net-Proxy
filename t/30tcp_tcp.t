use Test::More;
use strict;
use warnings;
use IO::Socket::INET;
use t::Util;

use Net::Proxy;

my @lines = (
    "swa_a_p bang swish bap crunch\n",
    "zlonk zok zapeth crunch_eth crraack\n",
    "glipp zwapp urkkk cr_r_a_a_ck glurpp\n",
    "zzzzzwap thwapp zgruppp awk eee_yow\n",
);
my $tests = @lines;

plan tests => $tests;

# lock 2 ports
my @free        = find_free_ports(2);
my $proxy_port  = $free[0]->sockport();
my $server_port = $free[1]->sockport();

SKIP: {
    skip "Not enough available ports", $tests if @free < 2;

    my $proxy = Net::Proxy->new(
        {   in => { type => 'tcp', host => 'localhost', port => $proxy_port },
            out =>
                { type => 'tcp', host => 'localhost', port => $server_port },
        }
    );

    $proxy->register();

    # close the ports before forking
    $_->close() for @free;

    my $pid = fork;

SKIP: {
        skip "fork failed", $tests if !defined $pid;
        if ( $pid == 0 ) {

            # the child process runs the proxy
            Net::Proxy->mainloop(1);
            exit;
        }
        else {

            # wait for the proxy to set up
            sleep 1;

            # the parent process does the testing
            my $listener = IO::Socket::INET->new(
                Listen    => 1,
                LocalAddr => 'localhost',
                LocalPort => $server_port,
                Proto     => 'tcp',
            ) or skip "Couldn't start the server: $!", $tests;
            my $client = IO::Socket::INET->new(
                PeerAddr => 'localhost',
                PeerPort => $proxy_port,
                Proto    => 'tcp',
            ) or skip "Couldn't start the client: $!", $tests;

            my $server = $listener->accept()
             or skip "Proxy didn't connect: $!", $tests;

            # send some data through
            for my $line (@lines) {
                print $client $line;
                is( <$server>, $line, "Line received" );
            }
        }

    }
}
