use Test::More;
use strict;
use warnings;
use Net::Proxy;

my @messages = (
    'ham tomato shrubbery pate herring truffle lobster aubergine',
    'kn na vn pk cy hn yu cc',
    'thwack kayo zlonk qunckkk zlott cr_r_a_a_ck clunk_eth bang',
    'The_Witch_of_Kaan Pipil_Khan Minstrel Sage Captain_Ahax Groo Chakaal',
    'barry wendel_j_stone_iv myron laura ed richard millard_bullrush dilbert',
    'lbrocard hvds ni_s gbarr lwall cbail mschwern rgarcia',
    'XPT MUR CNY MDL GHC MWK YER LTL',
    'elk wapiti antler alces_alces oryx moose caribou eland',
    'Jimmy_Carter Ronald_Reagan Chester_Arthur George_Washington Gerald_Ford',
    'Woodstock Rerun Peppermint_Patty Schroeder Pigpen Lucy Snoopy Linus',
    'manganese eckstine lowenstein gebrail gland maijstral girgis godolphin',
    'corge quux foobar fred waldo garply fubar grault',
);
my @expected = @messages[4,6,7,8];

my $err = 'stderr.out';

plan tests => my $tests = @expected;

SKIP: {

    # logs are sent to STDERR
    # (this is not a very nice way to spit logging info)
    # so, dup STDERR and save it to stderr.out
    open OLDERR, ">&STDERR" or skip "Can't dup STDERR: $!", $tests;
    open STDERR, '>', $err or skip "Can't redirect STDERR: $!", $tests;
    select STDERR;
    $| = 1;    # make unbuffered

    # run our tests now
    my $i = 0;
    Net::Proxy->notice( $messages[ $i++ ] );
    Net::Proxy->info( $messages[ $i++ ] );
    Net::Proxy->set_verbosity(0);
    Net::Proxy->notice( $messages[ $i++ ] );
    Net::Proxy->info( $messages[ $i++ ] );
    Net::Proxy->set_verbosity(1);
    Net::Proxy->notice( $messages[ $i++ ] );
    Net::Proxy->info( $messages[ $i++ ] );
    Net::Proxy->set_verbosity(2);
    Net::Proxy->notice( $messages[ $i++ ] );
    Net::Proxy->info( $messages[ $i++ ] );
    Net::Proxy->set_verbosity(1);
    Net::Proxy->notice( $messages[ $i++ ] );
    Net::Proxy->info( $messages[ $i++ ] );
    Net::Proxy->set_verbosity(0);
    Net::Proxy->notice( $messages[ $i++ ] );
    Net::Proxy->info( $messages[ $i++ ] );

    # get the old STDERR back
    open STDERR, ">&OLDERR" or die "Can't dup OLDERR: $!";
    close OLDERR;

    # read stderr.out
    open my $fh, $err or skip "Unable to open $err: $!";
    
    $i = 0;
    while(<$fh>) {
        is( $_, "$expected[$i]\n", "Expected line $i" );
        $i++;
    }

    # and remove all files
    unlink $err;
}

