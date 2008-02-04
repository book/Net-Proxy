use strict;
use warnings;
use Test::More;
use Net::Proxy::Message;
use Net::Proxy::MessageQueue;

BEGIN { eval 'use Time::HiRes qw( time )' }

my @msgs = (

    # [ from, to, direction, message ]
    [ normal_1 => thunk  => vronk  => Net::Proxy::Message->new('rip') ],
    [ normal_2 => swish  => zap    => Net::Proxy::Message->new('thwacke') ],
    [ normal_3 => thwapp => touche => Net::Proxy::Message->new('zok') ],
    [ normal_4 => zowie  => owww   => Net::Proxy::Message->new('clank') ],
);

my @timed = (
    [   timed_3 => aiieee => thwape =>
            Net::Proxy::Message->new( zowie => { _in_ => 3 } )
    ],
    [   timed_1 => slosh => bang =>
            Net::Proxy::Message->new( splatt => { _at_ => time + 1 } )
    ],
    [   timed_2 => crash => ker_plop =>
            Net::Proxy::Message->new( zowie => { _in_ => 2 } )
    ],
);

# times when timed messages will be sent
my @times = map { time + $_ } 1 .. 3;

plan tests => @msgs + @timed + 7;

# empty queue
is_deeply( [ Net::Proxy::MessageQueue->next() ],
    [], 'next() in list context' );
is( Net::Proxy::MessageQueue->next(), undef, 'next() in scalar context' );
is( Net::Proxy::MessageQueue->timeout, undef, 'No timeout' );

# add the messages
Net::Proxy::MessageQueue->queue(@msgs, @timed );
cmp_ok( Net::Proxy::MessageQueue->timeout, '>', 0, 'Timeout >  0' );
cmp_ok( Net::Proxy::MessageQueue->timeout, '<=', 1, 'Timeout <= 1' );

# receive the messages
my $n = 0;

is_deeply(
    [ Net::Proxy::MessageQueue->next() ],
    [ $msgs[ $n++ ] ],
    'Normal message'
);

# wait for the right time
select( undef, undef, undef, 0.25 ) while time < $times[0];
is_deeply(
    [ Net::Proxy::MessageQueue->next() ],
    [ $timed[1] ],
    'Timed message'
);

# wait again
select( undef, undef, undef, 0.25 ) while time < $times[1];
is_deeply(
    [ Net::Proxy::MessageQueue->next() ],
    [ $timed[2] ],
    'Timed message'
);
is_deeply(
    [ Net::Proxy::MessageQueue->next() ],
    [ $msgs[ $n++ ] ],
    'Normal message'
);
is_deeply(
    [ Net::Proxy::MessageQueue->next() ],
    [ $msgs[ $n++ ] ],
    'Normal message'
);

# wait for the last timed message
select( undef, undef, undef, 0.25 ) while time < $times[2];
is_deeply(
    [ Net::Proxy::MessageQueue->next() ],
    [ $timed[0] ],
    'Timed message'
);
is_deeply(
    [ Net::Proxy::MessageQueue->next() ],
    [ $msgs[ $n++ ] ],
    'Normal message'
);

# queue empty again
is_deeply( [ Net::Proxy::MessageQueue->next() ],
    [], 'next() in list context' );
is( Net::Proxy::MessageQueue->next(), undef, 'next() in scalar context' );

