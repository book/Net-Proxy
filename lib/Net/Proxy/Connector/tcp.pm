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

# READ
*read_from = \&Net::Proxy::Connector::raw_read_from;

# WRITE
*write_to = \&Net::Proxy::Connector::raw_write_to;

1;

__END__

=head1 NAME

Net::Proxy::Connector::tcp - Net::Proxy connector for standard tcp proxies

=head1 SYNOPSIS

    # sample proxy using Net::Proxy::Connector::tcp
    use Net::Proxy;

    my $proxy = Net::Proxy->new(
        in  => { proto => tcp, port => '6789' },
        out => { proto => tcp, host => 'remotehost', port => '9876' },
    );
    $proxy->register();

    Net::Proxy->mainloop();

=head1 DESCRIPTION

C<Net::Proxy::Connector::tcp> is a connector for handling basic, standard
TCP connections.

=head1 CONNECTOR OPTIONS

The connector accept the following options:

=head2 C<in>

=over 4

=item host

I<(optional)> The listening address. If not given, the default is
C<localhost>.

=item port

The listening port.

=back

=head2 C<out>

=over 4

=item host

The remote host.

=item port

The remote port.

=back

=head1 AUTHOR

Philippe 'BooK' Bruhat, C<< <book@cpan.org> >>.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Philippe 'BooK' Bruhat, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

