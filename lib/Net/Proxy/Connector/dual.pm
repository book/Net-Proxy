package Net::Proxy::Connector::dual;
use strict;
use warnings;
use Carp;

use Net::Proxy::Connector;
our @ISA = qw( Net::Proxy::Connector );

sub init {
    my ($self) = @_;

    # check connectors
    for my $conn (qw( client_first server_first )) {
        croak "'$conn' connector required" if !exists $self->{$conn};

        croak "'$conn' connector must be a HASHREF"
            if ref $self->{$conn} ne 'HASH';

        croak "'type' key required for '$conn' connector'"
            if !exists $self->{$conn}{type};

        # load the class
        my $class = 'Net::Proxy::Connector::' . $self->{$conn}{type};
        eval "require $class";
        croak "Couldn't load $class for '$conn' connector: $@" if $@;

        # create and store the Connector object
        $self->{$conn} = $class->new( $self->{$conn} );
        $self->{$conn}->set_proxy($self->{_proxy_});
    }

    # other parameters
    $self->{timeout} ||= 1;    # by default wait a second

    return;
}

# IN
*listen = \&Net::Proxy::Connector::raw_listen;

sub accept_from {
    my ( $self, $listen ) = @_;
    my $sock = $listen->accept();
    die $! unless $sock;

    # find out who speaks first
    # if the client talks first, it's a client_first connection
    my $waiter = IO::Select->new($sock);
    my @waited = $waiter->can_read( $self->{timeout} );
    my $type   = @waited ? 'client_first' : 'server_first';

    # do the outgoing connection
    $self->_out_connect_from($self->{$type}, $sock);

    return $sock;
}

# OUT

# READ
*read_from = \&Net::Proxy::Connector::raw_read_from;

# WRITE
*write_to = \&Net::Proxy::Connector::raw_write_to;

1;

__END__

=head1 NAME

Net::Proxy::Connector::dual - Y-shaped Net::Proxy connector

=head1 DESCRIPTION

C<Net::Proxy::Connecter::dual> is a C<Net::Proxy::Connector>
that can forward the connection to two distinct services,
based on the client connection, before any data is exchanged.

=head1 CONNECTOR OPTIONS

This connector can only work as an C<in> connector.

=over 4

=item * server_first

Typically a SSH server or any service that sends a banner line.

=item * client_first

Typically a web server or SSL server.

=back

=head1 AUTHOR

Philippe 'BooK' Bruhat, C<< <book@cpan.org> >>.

=head1 ACKNOWLEDGMENTS

This module is based on a script named B<sslh>, which I wrote with
Frédéric Plé C<< <sslh@wattoo.org> >> (who had the original insight
about the fact that not all servers speak first on the wire).

Frédéric wrote a C program, while I wrote a Perl script (based on my
experience with B<connect-tunnel>).

Now that C<Net::Proxy> is available, I've ported the Perl script to use it.

=head1 COPYRIGHT

Copyright 2006 Philippe 'BooK' Bruhat, All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

