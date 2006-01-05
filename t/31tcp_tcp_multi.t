use Test::More;
use strict;
use warnings;
use IO::Socket::INET;
use t::Util;
use POSIX qw( INT_MAX );

use Net::Proxy;

# dummy data
my @lines = (
    "swa_a_p bang swish bap crunch\n",
    "zlonk zok zapeth crunch_eth crraack\n",
    "glipp zwapp urkkk cr_r_a_a_ck glurpp\n",
    "zzzzzwap thwapp zgruppp awk eee_yow\n",
    "ker_plop spla_a_t swoosh cr_r_a_a_ck bang_eth pam uggh\n",
    "AEGEAN_NUMBER_NINETY MATHEMATICAL_SANS_SERIF_ITALIC_SMALL_Y\n",
    "YI_SYLLABLE_SHUX ARABIC_LIGATURE_THEH_WITH_REH_FINAL_FORM\n",
    "TAG_PLUS_SIGN CYPRIOT_SYLLABLE_RE\n",
    "TAG_LATIN_CAPITAL_LETTER_S YI_SYLLABLE_QYRX\n",
    "MATHEMATICAL_DOUBLE_STRUCK_CAPITAL_U HALFWIDTH_HANGUL_LETTER_YEO\n",
    "linguine lasagne_ricce chiocciole\n",
    "fusilli_tricolore sedani_corti galla_mezzana\n",
    "fettucce_ricce maniche chifferi_rigati\n",
    "mista lasagne_festonate_a_nidi nidi\n",
    "capelvenere parigine lacchene\n",
    "occhi_di_passero guanti ditali\n",
);

# compute a seed and show it
my $seed = @ARGV ? $ARGV[0] : int rand INT_MAX;
diag "Random seed $seed";
srand $seed;

# compute random configurations
my @confs = sort { $a->[0] <=> $b->[0] }
    map { [ int rand 16, int rand 8 ] } 1 .. 3;
my $tests = my $first = int rand 8;
$tests += $_->[1] for @confs;

# show the config if 
if( @ARGV ) { 
    diag sprintf "%2d %2d", @$_ for ( [ 0, $first ], @confs );
}
plan tests => $tests;

# lock 2 ports
my @free        = find_free_ports(2);
my $proxy_port  = $free[0]->sockport();
my $server_port = $free[1]->sockport();

SKIP: {
    skip "Not enough available ports", $tests if @free < 2;

    # close the ports before forking
    $_->close() for @free;

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

            Net::Proxy->mainloop( @confs + 1 );
            exit;
        }
        else {

            # wait for the proxy to set up
            sleep 1;

            # start the server
            my $listener = listen_on_port($server_port)
                or skip "Couldn't start the server: $!", $tests;

            # create the first pair
            my %pairs;
            {
                my $pair = (
                    [   connect_to_port($proxy_port),
                        scalar $listener->accept(),
                        $first, 0
                    ]
                );
                %pairs = ( $pair => $pair );
            }

            my $step = my $n = my $count = 0;
            while (%pairs || @confs) {

                # create a new connection
            CONF:
                while ( @confs && $confs[0][0] == $step ) {
                    my $conf   = shift @confs;
                    my $client = connect_to_port($proxy_port)
                        or do {
                        diag "Couldn't start the client: $!";
                        next CONF;
                        };
                    my $server = $listener->accept()
                        or do { diag "Proxy didn't connect: $!"; next CONF; };
                    my $pair = [ $client, $server, $conf->[1], ++$count ];
                    $pairs{$pair} = $pair;
                }

            PAIR:
                for my $pair (values %pairs) {

                    # close the connection if finished
                    if ( $pair->[2] <= 0 ) {
                        $pair->[0]->close();
                        $pair->[1]->close();
                        delete $pairs{$pair};
                        next PAIR;
                    }

                    # send data through the connection
                    $n %= @lines;
                    my $line = $lines[$n];
                    print { $pair->[ $step % 2 ] } $line;
                    is( $pair->[ 1 - $step % 2 ]->getline(),
                        $line, "Step $step: line $n sent through pair $pair->[3]" );
                    $pair->[2]--;
                    $n++;

                }
                $step++;
            }
        }
    }
}

