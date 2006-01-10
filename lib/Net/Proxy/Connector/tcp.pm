package Net::Proxy::Connector::tcp;
use strict;
use warnings;
use IO::Socket::INET;

use Net::Proxy::Connector;
our @ISA = qw( Net::Proxy::Connector );

# IN
*listen = \&Net::Proxy::Connector::raw_listen;

sub accept_from {
    my ($self, $listen) = @_;
    my $sock = $listen->accept();
    die $! unless $sock;
    return $sock;
}

# OUT
sub connect {
    my ($self) = @_;
    my $sock = IO::Socket::INET->new(
        PeerAddr  => $self->{host} || 'localhost',
        PeerPort  => $self->{port},
        Proto     => 'tcp',
    );
    die $! unless $sock;
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
        in  => { type => tcp, port => '6789' },
        out => { type => tcp, host => 'remotehost', port => '9876' },
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

=item *

host

The listening address. If not given, the default is C<localhost>.

=item *

port

The listening port.

=back

=head2 C<out>

=over 4

=item *

host

The remote host.

=item *

port

The remote port.

=back

=head1 AUTHOR

Philippe 'BooK' Bruhat, C<< <book@cpan.org> >>.

=head1 COPYRIGHT

Copyright 2006 Philippe 'BooK' Bruhat, All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

