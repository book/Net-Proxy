use strict;
use warnings;
use Test::More;
use Net::Proxy;

my @msg = (
    { message => 'Barbapapa Barbibul Barbidur Barbalala', level => 1 },
    { message => 'caribou velvet_antler eland wapiti',    level => 4 },
    { message => 'holy_distortion holy_funny_bone',       level => 7 },
);

package MyLogger;
use strict;
use Test::More;
{
    my $i = 0;
    sub log {
        my ( $self, %args ) = @_;
        is_deeply( \%args, $msg[$i], "Log $i received" );
        $i++;
    }
}

package main;

plan tests => @msg + 3;

eval { Net::Proxy->add_loggers( 'zlonk' ); };
like( $@, qr/^zlonk cannot log\(\)/, 'Bad logging class');

eval { Net::Proxy->add_loggers( bless {}, 'Zlonk' ); };
like( $@, qr/^Zlonk=HASH\(0x\w+\) cannot log/, 'Bad logging object' );

eval { Net::Proxy->add_loggers( 'MyLogger' ); };
is( $@, '', 'add_logger()' );

Net::Proxy->log(%$_) for @msg;
