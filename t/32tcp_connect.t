use Test::More;
use strict;
use warnings;
use IO::Socket::INET;
use t::Util;

use Net::Proxy;

my @lines = (
    "fettuccia_riccia galla_genovese sedanetti pennine_rigate gobboni",
    "fenescecchie barbina gianduini umbricelli maniche",
    "gozzetti pepe tofarelle anelli_margherite_lisce farfallette",
    "sciviotti_ziti_rigati gobbini gomiti cravattine penne_di_zitoni",
    "amorosi cuoricini cicorie tempestina tortellini",
);
my $tests = @lines + 3;

plan tests => $tests;

# check required modules for this test case
eval { require LWP::UserAgent; };
skip "LWP::UserAgent required to test Net::Proxy::Connector::connect", $tests
  if $@;
eval { require HTTP::Daemon; };
skip "HTTP::Daemon required to test Net::Proxy::Connector::connect", $tests
  if $@;

# lock 2 ports
my @free = find_free_ports(2);

SKIP: {
    skip "Not enough available ports", $tests if @free < 2;

    my $proxy_port     = $free[0]->sockport();
    my $web_proxy_port = $free[1]->sockport();

    # close the ports before forking
    $_->close() for @free;

    my $pid = fork;

  SKIP: {
        skip "fork failed", $tests if !defined $pid;
        if ( $pid == 0 ) {

            # the child process runs the proxy
            my $proxy = Net::Proxy->new(
                {
                    in => {
                        type => 'tcp',
                        host => 'localhost',
                        port => $proxy_port
                    },
                    out => {
                        type       => 'connect',
                        host       => 'zlonk.crunch.com',
                        port       => 443,
                        proxy_host => 'localhost',
                        proxy_port => $web_proxy_port,
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
            my $listener = listen_on_port($web_proxy_port)
              or skip "Couldn't start the server: $!", $tests;
            my $client = connect_to_port($proxy_port)
              or skip_fail "Couldn't start the client: $!", $tests;
            my $server = $listener->accept()
              or skip_fail "Proxy didn't connect: $!", $tests;

            # turn the server socket into a HTTP::Daemon socket
            bless $server, 'HTTP::Daemon::ClientConn';

            # the server will first play the role of the web proxy,
            # and after a 200 OK will also act as a real server

            # check the request
            my $req = $server->get_request();
            is( $req->method(), 'CONNECT', 'Proxy did a CONNECT' );
            is( $req->uri(), 'zlonk.crunch.com:443', 'Target host:port' );

            my $headers = $req->headers();
            is(
                $headers->header('User-Agent'),
                'Net::Proxy/$Net::Proxy::VERSION',
                'User-Agent header'
            );

            # first time, the web proxy says 200
            my $res = HTTP::Response->new('200');
            $server->send_response($res);

            # send some data through
            for my $line (@lines) {
                ( $client, $server ) = random_swap( $client, $server );
                print $client $line;
                is( <$server>, $line, "Line received" );
            }
            $client->close();
            $server->close();

            # second time, the web proxy says 403 (how to test this?)
            # TODO
        }
    }
}
