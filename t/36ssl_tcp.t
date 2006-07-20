use Test::More;
use strict;
use warnings;
use IO::Socket::INET;
use IO::Socket::SSL;
use File::Spec::Functions;
use t::Util;

use Net::Proxy;

my @lines = (
    "swa_a_p bang swish bap crunch\n",
    "zlonk zok zapeth crunch_eth crraack\n",
    "glipp zwapp urkkk cr_r_a_a_ck glurpp\n",
    "zzzzzwap thwapp zgruppp awk eee_yow\n",
);
my $tests = @lines;

# TODO: skip all if no IO::Socket::SSL

plan tests => $tests;

init_rand(@ARGV);

# lock 2 ports
my @free = find_free_ports(2);

$IO::Socket::SSL::DEBUG = $ENV{NET_PROXY_VERBOSITY} || 0;

SKIP: {
    skip "Not enough available ports", $tests if @free < 2;

    my ( $proxy_port, $server_port ) = @free;
    my $pid = fork;
    skip "proxy fork failed", $tests if !defined $pid;
    if ( $pid == 0 ) {

        my $proxy = Net::Proxy->new(
            {
                in => {
                    type          => 'ssl',
                    host          => 'localhost',
                    port          => $proxy_port,
                    timeout       => 1,
                    SSL_cert_file => catfile( 't', 'test.cert' ),
                    SSL_key_file  => catfile( 't', 'test.key' ),
                },
                out => {
                    type => 'tcp',
                    host => 'localhost',
                    port => $server_port,
                },
            }
        );

        $proxy->register();

        Net::Proxy->set_verbosity( $ENV{NET_PROXY_VERBOSITY} || 0 );
        Net::Proxy->mainloop(1);

        exit;
    }
    else {

      SKIP: {

            # fork a server
            $pid = fork;
            skip "server fork failed", $tests if !defined $pid;
            if ( $pid == 0 ) {
                my $listener = listen_on_port($server_port)
                  or skip "Couldn't start the server: $!", $tests;

                my $server = $listener->accept()
                  or skip "Proxy didn't connect: $!", $tests;

                for my $line (@lines) {
                    is( <$server>, $line, "Line received" );
                }
                $server->close();

                # the child process runs the proxy
                exit;
            }
            else {

                # wait for the proxy to set up
                sleep 1;

                # the parent process does the testing
                my $client = IO::Socket::SSL->new(
                    PeerAddr => 'localhost',
                    PeerPort => $proxy_port
                  )
                  or skip "Couldn't start the client: $!", $tests;

                for my $line (@lines) {

                    # send some data through
                    print $client $line;
                }
                $client->close();
            }
        }
    }
}
