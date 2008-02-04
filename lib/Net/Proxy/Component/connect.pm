use strict;
use warnings;

package Net::Proxy::Component::connect;
use Net::Proxy::Component;
our @ISA = qw( Net::Proxy::Component );
__PACKAGE__->build_factory_class();

use LWP::UserAgent;

sub START_CONNECTION {
    my ( $self, $message, $from, $direction ) = @_;

    # connect to the proxy
    my $req = HTTP::Request->new(
        CONNECT => "http://$self->{host}:$self->{port}/" );
    my $res = $self->{agent}->request($req);

    # authentication failed
    # FIXME - send a message back
    die $res->status_line() if !$res->is_success();

    # the socket connected to the proxy
    $self->{sock} = $res->{client_socket};

    # now turn into a classic tcp component
    bless $self, 'Net::Proxy::Component::tcp';
    Net::Proxy->set_compdir_for(
        $self->{sock} => $self,
        $self->opposite($direction)
    );
    Net::Proxy->watch_reader_sockets( $self->{sock} );

    return;
}

package Net::Proxy::ComponentFactory::connect;
use Carp;

sub init {
    my ($self) = @_;

    # check params
    for my $attr (qw( host port )) {
        croak "$attr parameter is required"
            if !exists $self->{$attr};
    }

    # create a user agent class linked to this connector
    $self->{agent} = my $ua = LWP::UserAgent->new(
        agent      => $self->{proxy_agent},
        keep_alive => 1,
    );

    # set the agent proxy
    if ( $self->{proxy_host} ) {
        $self->{proxy_port} ||= 8080;
        $self->{proxy_pass} ||= '';
        my $auth = $self->{proxy_user}
            ? "$self->{proxy_user}:$self->{proxy_pass}\@"
            : '';
        $ua->proxy(
            http => "http://$auth$self->{proxy_host}:$self->{proxy_port}/" );
    }
    else {
        $self->{agent}->env_proxy();
    }

    # no proxy defined!
    croak 'proxy_host parameter is required' unless $ua->proxy('http');

    return $self;
}

1;

__END__

=head1 NAME

Net::Proxy::Component::connect - Create CONNECT tunnels through HTTP proxies

=head1 SYNOPSIS

    # sample proxy using Net::Proxy::Component::tcp
    #                and Net::Proxy::Component::connect
    use Net::Proxy;

    # listen on localhost:6789
    # and proxy to remotehost:9876 through proxy.company.com:8080
    # using the given credentials
    my $chain = Net::Proxy->chain(
        {   type => 'tcp',
            port => '6789'
        },
        {   type        => 'connect',
            host        => 'remotehost',
            port        => '9876',
            proxy_host  => 'proxy.company.com',
            proxy_port  => '8080',
            proxy_user  => 'jrandom',
            proxy_pass  => 's3kr3t',
            proxy_agent => 'Mozilla/4.04 (X11; I; SunOS 5.4 sun4m)',
        },
    );
    $chain->register();

    Net::Proxy->mainloop();

=head1 DESCRIPTION

C<Net::Proxy::Connecter::connect> is a C<Net::Proxy::Component> that
uses the HTTP CONNECT method to ask the proxy to create a tunnel to
an outside server.

Be aware that some proxies are set up to deny the creation of some
outside tunnels (either to ports other than 443 or outside a specified
set of outside hosts).

This connector is only an "out" connector.

=head1 COMPONENT OPTIONS

C<Net::Proxy::Component::connect> accepts the following options:

=over 4

=item * host

The destination host.

=item * port

The destination port.

=item * proxy_host

The web proxy name or address.

=item * proxy_port

The web proxy port.

=item * proxy_user

The authentication username for the proxy.

=item * proxy_pass

The authentication password for the proxy.

=item * proxy_agent

The user-agent string to use when connecting to the proxy.

=back

=head1 AUTHOR

Philippe 'BooK' Bruhat, C<< <book@cpan.org> >>.

=head1 BUGS

All the authentication schemes supported by C<LWP::UserAgent> should be
supported (we use an C<LWP::UserAgent> internally to contact the proxy).

This means we should also support NTLM, since it is supported as from
C<libwww-perl> 5.66. C<Net::Proxy::Component::connect> has not been
actually tested with NTLM, though. Any report of success or failure
with a NTLM proxy will be appreciated.

=head1 HISTORY

This module is based on my script C<connect-tunnel>, that provided
a command-line interface to create tunnels though HTTP proxies.
It was first published on CPAN on March 2003.

A better version of C<connect-tunnel> (using C<Net::Proxy>) is provided
this distribution.

=head1 COPYRIGHT

Copyright 2006-2008 Philippe 'BooK' Bruhat, All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

