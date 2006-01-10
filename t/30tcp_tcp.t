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

plan tests => $tests + 1;

# lock 2 ports
my @free = find_free_ports(2);

SKIP: {
    skip "Not enough available ports", $tests if @free < 2;

    my ($proxy_port, $server_port) = @free;
    my $pid = fork;

SKIP: {
        skip "fork failed", $tests if !defined $pid;
        if ( $pid == 0 ) {

            # the child process runs the proxy
            my $proxy = Net::Proxy->new(
                {   in => {
                        type => 'tcp',
                        host => 'localhost',
                        port => $proxy_port
                    },
                    out => {
                        type => 'tcp',
                        host => 'localhost',
                        port => $server_port
                    },
                }
            );

            $proxy->register();

            Net::Proxy->mainloop(1);
            exit;
        }
        else {

            # wait for the proxy to set up
            sleep 1;

            # the parent process does the testing
            my $listener = listen_on_port($server_port)
                or skip "Couldn't start the server: $!", $tests;
            my $client = connect_to_port($proxy_port)
                or skip "Couldn't start the client: $!", $tests;
            my $server = $listener->accept()
                or skip "Proxy didn't connect: $!", $tests;

            # mainloop(1) limits incoming connections to 1
            my $client2 = connect_to_port($proxy_port);
            is( $client2, undef, "second client fails: $!");

            # send some data through
            for my $line (@lines) {
                print $client $line;
                is( <$server>, $line, "Line received" );
                ($client, $server) = ($server, $client); # swap directions
            }
            $client->close();
            $server->close();
        }
    }
}
