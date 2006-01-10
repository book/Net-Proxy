use Test::More;
use IPC::Open3;
use File::Spec::Functions;
use strict;

my @scripts = glob catfile( 'script', '*' );

plan tests => scalar @scripts;

for my $script (@scripts) {
    local ( *IN, *OUT, *ERR );
    my $pid = open3( \*IN, \*OUT, \*ERR, "$^X -Mblib -c $script" );
    wait;

    local $/ = undef;
    my $errput = <ERR>;
    like( $errput, qr/syntax OK/, "'$script' compiles" );
}



