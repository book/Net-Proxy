use strict;
use warnings;
use Test::More;
use Net::Proxy::MessageQueue;

BEGIN { eval 'use Time::HiRes qw( time )' }

my @msgs = (

    # [ from, to, mesg, direction ]
    [ normal_1 => thunk  => vronk  => rip     => ],
    [ normal_2 => swish  => zap    => thwacke => ],
    [ normal_3 => thwapp => touche => zok     => ],
    [ normal_4 => zowie  => owww   => clank   => ],
);
my @timed = (

    # [ from, to, mesg, direction ], time_ref
    [ [ timed_3 => aiieee => thwape   => zowie  => ], in => 3 ],
    [ [ timed_1 => slosh  => bang     => splatt => ], at => time + 1 ],
    [ [ timed_2 => crash  => ker_plop => zowie  => ], in => 2 ],
);

# times when timed messages will be sent
my @times = map { time + $_ } 1 .. 3;

plan tests => @msgs + @timed + 5;

# empty queue
is_deeply( [ Net::Proxy::MessageQueue->next() ],
    [], 'next() in list context' );
is( Net::Proxy::MessageQueue->next(), undef, 'next() in scalar context' );

# add the messages
Net::Proxy::MessageQueue->queue($_)  for @msgs;
Net::Proxy::MessageQueue->timed(@$_) for @timed;

# bad call to timed()
eval { Net::Proxy::MessageQueue->timed( [], le => 1 ) };
like( $@,
    qr/^Unexpected time reference 'le 1'/,
    'timed() call with a wrong reference'
);

# receive the messages
my $n = 0;

is_deeply(
    [ Net::Proxy::MessageQueue->next() ],
    [ $msgs[ $n++ ] ],
    'Normal message'
);

# wait for the right time
select( undef, undef, undef, 0.5 ) while time < $times[0];
is_deeply(
    [ Net::Proxy::MessageQueue->next() ],
    [ $timed[1][0] ],
    'Timed message'
);

# wait again
select( undef, undef, undef, 0.5 ) while time < $times[1];
is_deeply(
    [ Net::Proxy::MessageQueue->next() ],
    [ $timed[2][0] ],
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

# wait for the last timed message
select( undef, undef, undef, 0.5 ) while time < $times[2];
is_deeply(
    [ Net::Proxy::MessageQueue->next() ],
    [ $timed[0][0] ],
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

