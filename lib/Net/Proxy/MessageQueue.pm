package Net::Proxy::MessageQueue;

use strict;
use warnings;
use Carp;

# if available, transparently use Time::HiRes for fractional recall times
BEGIN { eval 'use Time::HiRes qw( time )' }

# the two messages queues we manage
my @Queue;
my @Timed;

sub queue {
    unshift @Queue, $_[1];
    return;
}

sub timed {
    my ( undef, $messages, $ref, $secs ) = @_;

    my $expires
        = $ref eq 'in' ? time + $secs
        : $ref eq 'at' ? $secs
        :                croak "Unexpected time reference '$ref $secs'";

    my $i = 0;
    $i++ while @Timed > $i && $Timed[$i][0] > $expires;
    splice @Timed, $i, 0, [ $expires, $messages ];
    return;
}

sub next {

    # expired timed message
    return ( pop @Timed )->[1] if @Timed && $Timed[-1][0] <= time;

    # next normal message
    return pop @Queue if @Queue;

    # no more messages
    return;
}

sub timeout {
    my $timeout = @Timed ? $Timed[-1][0] - time : 0;
    return $timeout > 0 ? $timeout : 0;
}

1;

__END__

=head1 NAME

Net::Proxy::MessageQueue - 

=head1 SYNOPSYS

=head1 DESCRIPTION

This is an internal class, only meant to be used by C<Net::Proxy>
and C<Net::Proxy::Node>.

The queue manages two types of messages that have to be delivered to
various components:

=over 4

=item *

timed messages, which are meant to be delivered at a specific time

=item *

"normal" messages which are delivered as soon as possible
(if no timed message has a higher priority)

=back

A I<message context> is a reference to an array containing: the sender
(or source), the receiver (or destination), the message group itself
and the direction of the message.

=head1 METHODS

C<Net::Proxy::MessageQueue> supports the following class methods:

=over 4

=item queue( [ $from, $to, $messages, $direction ] )

Add the message context (source, destination, message group and direction)
to the queue.

=item timed( [ $from, $to, $messages, $direction ], in => $secs )

=item timed( [ $from, $to, $messages, $direction ], at => $secs )

Register the message context to be delivered at a specific date and
time, depending on the last two parameters.

C<in> introduces an offset in seconds from the current time.

C<at> introduces an absolute date, in seconds since the I<epoch>.

=item next()

Return the next message context.

=item timeout()

Return the time available before the next timed message context
is ready to be sent.

=back

Please note that since the queue is global, C<Net::Proxy::MessageQueue>
doesn't provide a way to create object instances. Think of it as a
singleton, if you wish.

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book@cpan.org> >>.

=head1 COPYRIGHT

Copyright 2008 Philippe Bruhat (BooK), All Rights Reserved.
 
=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

