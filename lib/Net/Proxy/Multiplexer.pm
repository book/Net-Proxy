package Net::Proxy::Multiplexer;

use strict;
use warnings;

use Scalar::Util qw(refaddr);
use IO::Select;

our $VERSION = '0.01';

# class data
my %OWNER_OF;    # links sockets to the Net::Proxy object that owns them
my %PROXY;       # keeps track of all Net::Proxy objects
my $SELECT = IO::Select->new();

sub debug {
    use Data::Dumper;
    print Data::Dumper->Dump( [\%OWNER_OF, \%PROXY, $SELECT], [qw(*OWNER_OF *PROXY $SELECT)] );
}

sub register_proxy {
    my ( $class, $proxy ) = @_;

    # keep track of all involved proxies
    $PROXY{ refaddr $proxy} = $proxy;

    return;
}

sub unregister_proxy {
    my ($class, $proxy ) = @_;
    delete $PROXY{ refaddr $proxy };
    return;
}

sub register_proxy_sockets {
    my ( $class, $proxy, @socks ) = @_;

    # keep track of all involved proxies
    $class->register_proxy($proxy);

    # link each socket back to its proxy
    # and watch the socket from now on
    for my $sock (@socks) {
        $OWNER_OF{ refaddr $sock} = $proxy;
        $SELECT->add( $sock );
    }

    return;
}

sub mainloop {

    # initialise all proxies
    for my $proxy ( values %PROXY ) {
        $proxy->init();
    }

    # loop indefinitely
    while ( my @ready = $SELECT->can_read() ) {
        for my $sock (@ready) {
            $OWNER_OF{ refaddr $sock}->process_socket($sock);
        }
    }
}

1;

__END__

=head1 NAME

Net::Proxy::Multiplexer - The Net::Proxy multiplexer

=head1 SYNOPSIS

    use Net::Proxy;

    # Configuration of various Net::Proxy objects
    # ...

    # Start proxying
    Net::Proxy::Multiplexer->mainloop();

    # or, as a convenience method of Net::Proxy
    Net::Proxy->mainloop();

=head1 DESCRIPTION

The multiplexer handles all the Net::Proxy objects.

It loops on all the sockets ready for reading, and
pass the sockets to their proxies so that they can
handle the proxying logic.

The C<Net::Proxy::Multiplexer> is a singleton, and it
is used automatically by the various C<Net::Proxy> objects
to register their sockets when needed.

=head1 METHODS

The class supports the following methods:

=over 4

=item register_proxy( $proxy )

Register the C<Net::Proxy> object with the multiplexer.

=item register_proxy_sockets( $proxy, @sockets )

Register the opened sockets in C<@sockets> with the C<$proxy>
that will handle the data coming from them.

=item mainloop()

This method intialises all the listening sockets and pass around
the sockets that have data ready to be read.

This loop never returns.

=back

=head1 AUTHOR

=head1 COPYRIGHT

=head1 LICENSE


