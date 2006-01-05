use strict;
use warnings;
use IO::Socket::INET;

# return sockets connected to free ports
# we can use sockport() to learn the port values
# and close() to close the socket just before reopening it
sub find_free_ports {
    my $n    = shift;
    my $port = 30000;
    my @socks;

    while ( @socks < $n && $port > 1023 ) {

        my $sock = IO::Socket::INET->new(
            Listen    => 1,
            LocalAddr => 'localhost',
            LocalPort => $port,
            Proto     => 'tcp',
        );

        push @socks, $sock if defined $sock;
        $port--;
    }

    # failure
    return if @socks != $n;

    return @socks;
}

# return a socket connected to port $port on localhost
sub connect_to_port {
    my ($port) = @_;
    return IO::Socket::INET->new(
        PeerAddr => 'localhost',
        PeerPort => $port,
        Proto    => 'tcp',
    );
}

sub listen_on_port {
    my ($port) = @_;
    return IO::Socket::INET->new(
        Listen    => 1,
        LocalAddr => 'localhost',
        LocalPort => $port,
        Proto     => 'tcp',
    );
}

1;
