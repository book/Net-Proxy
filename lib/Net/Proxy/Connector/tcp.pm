package Net::Proxy::Connector::tcp;
use strict;
use warnings;
use Carp;
use IO::Socket::INET;

use Net::Proxy::Connector;
our @ISA = qw( Net::Proxy::Connector );

# IN
sub listen {
    my $self = shift;
    my $sock = IO::Socket::INET->new(
        Listen    => 1,
        LocalAddr => $self->{host},
        LocalPort => $self->{port},
        Proto     => 'tcp',
        ReuseAddr => 1,
    );
    croak $! unless $sock;

    return $sock;
}

sub accept_from {
    my ($self, $listen) = @_;
    my $sock = $listen->accept();
    croak $! unless $sock;
    return $sock;
}

# READ
*get_data_from = \&Net::Proxy::Connector::raw_data_from;

# WRITE
sub write_to {
    my ($self, $sock, $data) = @_;
    my $written = $sock->syswrite( $data );
    if( ! defined $written ) {
        carp sprintf("Read undef from %s:%s (Error %d: %s)\n",
                     $sock->sockhost(), $sock->sockport(), $!, "$!");
    }
    return;
}

# OUT
sub connect {
    my ($self) = @_;
    my $sock = IO::Socket::INET->new(
        PeerAddr  => $self->{host},
        PeerPort  => $self->{port},
        Proto     => 'tcp',
    );
    croak $! unless $sock;
    return $sock;
}

1;

__END__

=head1 NAME

Net::Proxy::Connector::tcp - Net::Proxy connector for standard tcp proxies

=head1 SYNOPSIS

    use Net::Proxy;

    my $proxy = Net::Proxy->new(
        in  => { proto => tcp, port => '6789' },
        out => { proto => tcp, host => 'remotehost', port => '9876' },
    );

    $proxy->register();

    Net::Proxy->mainloop();

=head1 DESCRIPTION

=head1 PROXY OPTIONS

=head1 AUTHOR

=head1 COPYRIGHT

=head1 LICENSE

