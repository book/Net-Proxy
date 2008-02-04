use Test::More;
use IPC::Open3;
use File::Spec::Functions;
use strict;

my @scripts = glob catfile( 'script', '*' );

plan tests => scalar @scripts;

my %prereq = ( 'script/connect-tunnel' => [qw( LWP::UserAgent )], );

for my $script (@scripts) {
SKIP: {
        my $skip;
        for my $module ( @{ $prereq{$script} } ) {
            eval {"use $module;"};
            $skip .= "$module " if $@;
        }
        skip "'$script' missing prereq: $skip", 1 if $skip;

        local ( *IN, *OUT, *ERR );
        my $pid = open3( \*IN, \*OUT, \*ERR, "$^X -Mblib -c $script" );
        wait;

        local $/ = undef;
        my $errput = <ERR>;
        like( $errput, qr/syntax OK/, "'$script' compiles" );
    }
}

