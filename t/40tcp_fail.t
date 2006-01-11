use Test::More;
use strict;
use warnings;
use IO::Socket::INET;
use t::Util;

use Net::Proxy;

plan tests => my $tests = 2;

# lock 2 ports
my @free = find_free_ports(4);

SKIP: {
    skip "Not enough available ports", $tests if @free < 4;

    my ( $proxy_port, $server_port, $proxy_port2, $server_port2 ) = @free;

    # test for mainloop failure
    # lock one proxy port
    my $server2 = listen_on_port( $proxy_port2 )
        or skip "Failed to lock port $proxy_port2", $tests;
    
    my $proxy2 = Net::Proxy->new(
        {   in => {
                type => 'tcp',
                host => 'localhost',
                port => $proxy_port2,
            },
            out => {
                type => 'tcp',
                host => 'localhost',
                port => $server_port2,
            },
        }
    );
    $proxy2->register();
    eval { Net::Proxy->mainloop(); };
    like( $@, qr/^Can't listen on localhost port \d+: /, 'Port in use' );
    $proxy2->unregister();

    # now fork and test
    my $pid = fork;

SKIP: {
        skip "fork failed", $tests if !defined $pid;
        if ( $pid == 0 ) {

            # the child process runs the proxy
            my $proxy = Net::Proxy->new(
                {   in => {
                        type => 'tcp',
                        host => 'localhost',
                        port => $proxy_port,
                    },
                    out => {
                        type => 'tcp',
                        host => 'localhost',
                        port => $server_port,
                    },
                },
            );

            $proxy->register();
            Net::Proxy->mainloop(1);
            exit;
        }
        else {

            # wait for the proxy to set up
            sleep 1;

            # no server
            my $client = connect_to_port($proxy_port)
                or skip "Couldn't start the client: $!", $tests;

            # the client is actually not connected at all
            is_closed( $client, 'peer' );
            $client->close();
        }
    }
}
