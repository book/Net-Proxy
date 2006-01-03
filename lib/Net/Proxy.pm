package Net::Proxy;
use strict;
use warnings;
use Carp;
use Scalar::Util qw( refaddr );
use Net::Proxy::Multiplexer;
use Net::Proxy::Connector;

our $VERSION = '0.01';

sub new {
    my ($class, $args) = @_;

    my $self = bless {
        listeners => {},
    }, $class;

    croak "Argument to new() must be a HASHREF" if ref $args ne 'HASH';

    for my $conn (qw( in out )) {

        # check arguments
        croak "'$conn' connector required" if !exists $args->{$conn};

        croak "'$conn' connector must be a HASHREF"
            if ref $args->{$conn} ne 'HASH';

        croak "'type' key required for '$conn' connector'"
            if !exists $args->{$conn}{type};

        # load the class
        my $class = 'Net::Proxy::Connector::' . $args->{$conn}{type};
        eval "require $class";
        croak "Couldn't load $class for '$conn' connector" if $@;

        # create the Connector object
        $self->{$conn} = $class->new( $args->{$conn} );
    }

    return $self;
}

sub register {
    # register ourself with the multiplexer
    Net::Proxy::Multiplexer->register_proxy( $_[0] );
}

sub register_sockets {
    my ($self, @socks) = @_;
    Net::Proxy::Multiplexer->register_proxy_sockets( $self, @socks );
}

sub register_listeners {
    my ($self, @socks) = @_;
    $self->{listeners}{refaddr $_} = $_ for @socks;
    return;
}

sub has_listener { return exists $_[0]->{listeners}{refaddr $_[1] }; }

sub init {
    my $self = shift;

    # initialise the listening sockets
    my @socks = $self->{in}->listen();
    $self->register_listeners( @socks );
    $self->register_sockets( @socks );

    return @socks;
}

sub process_socket {
    my ($self, $sock) = @_;
    
    # if $sock is a listener
    if( $self->has_listener( $sock ) ) {
        print "listener $sock\n";
        my $in_proto = $self->{in}; # Net::Proxy::Connector->manager_of( $sock )

        # accept the connection
        my $in_sock = $in_proto->accept_from( $sock );

        # register the socket manager
        $in_proto->register_as_manager_of( $in_sock );

        # register the newly created socket with the multiplexer
        $self->register_sockets( $in_sock );
        Net::Proxy::Multiplexer->debug;
        Net::Proxy::Connector->debug;

        return;
    }
    else {
        # find out the peers
        my $in_mgr  = Net::Proxy::Connector->manager_of( $sock );
        print "reader $sock\n";

        # read the data coming in
        my $data = $in_mgr->read_from($sock);

        # TODO $data could even go through a few filters

        # send out the data
        my $peer = $in_mgr->get_peer();
        print "writer $peer\n";
        $peer->write_data( $data );

        return;
    }
}

# convenience method
sub mainloop {
    Net::Proxy::Multiplexer->mainloop();
}

1;

__END__

=head1 NAME

Net::Proxy - Proxy network connections using various protocols

=head1 SYNOPSIS

    use Net::Proxy;

    # proxy connections from localhost:6789 to remotehost:9876
    # using standard TCP connections
    my $proxy = Net::Proxy->new(
        in  => { proto => tcp, port => '6789' },
        out => { proto => tcp, host => 'remotehost', port => '9876' },
    );

    # register the proxy object
    $proxy->register();

    # and now proxy connections indefinitely
    Net::Proxy->mainloop();

=head1 DESCRIPTION

A C<Net::Proxy> object represents a proxy that accepts connections
and then relays the data transfered between the source and the destination.

The goal of this module is to abstract the different protocols used
to connect from the proxy to the destination.

=head1 AVAILABLE PROTOCOLS

All protocols are provided with the help of specialised classes.
The logic for protocol C<xxx> is provided by the C<Net::Proxy::Connector::xxx>
class.

=head2 tcp (C<Net::Proxy::tcp>)

=head2 Summary


     Connector | in parameters   | out parameters
    -----------+-----------------+----------------
     tcp       | host            | host
               | port            | port
    -----------+-----------------+----------------
     connect   | N/A             | host
               |                 | port
               |                 | proxy_host
               |                 | proxy_port
               |                 | proxy_user
               |                 | proxy_pass
               |                 | proxy_agent

=head1 AUTHOR

=head1 COPYRIGHT

=head1 LICENSE


}

1;

__END__

=head1 NAME

Net::Proxy - 


