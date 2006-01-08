use strict;
use warnings;
use IO::Socket::INET;

# return sockets connected to free ports
# we can use sockport() to learn the port values
# and close() to close the socket just before reopening it
sub find_free_ports {
    my $n = shift;
    my @socks;

    for ( 1 .. $n ) {
        my $sock = listen_on_port(0);
        if ($sock) {
            push @socks, $sock;
        }
    }
    diag join ' ', 'ports:', map { $_->sockport() } @socks;

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

# return a socket listening on $port on localhost
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
