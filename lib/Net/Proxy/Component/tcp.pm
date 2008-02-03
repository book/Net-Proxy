package Net::Proxy::Component::tcp;
use strict;
use warnings;
use IO::Socket::INET;

use Net::Proxy::Component;
our @ISA = qw( Net::Proxy::Component );
__PACKAGE__->build_factory_class();

my $BUFFSIZE = 4096;

sub init {
    my ($self) = @_;

    # set up some defaults
    $self->{host}    ||= 'localhost';
    $self->{timeout} ||= 1;
    $self->{buffer} = '';
}


#
# messages
#
sub ACCEPT {
    my ( $self, $message, $from, $direction ) = @_;

    # $from is the factory, whose socket we can accept() from
    $self->{sock} = $from->{sock}->accept();

    # FIXME - send an ERROR message
    die $! unless $self->{sock};

    # ask the proxy to put it at the front of our chain
    Net::Proxy->set_compdir_for( $self->{sock}, $self, $direction );
    Net::Proxy->watch_reader_sockets( $self->{sock} );

    # the connection has been accepted
    return Net::Proxy::Message->new( 'START_CONNECTION' );
}

sub CAN_READ {
    my ( $self, $message, $from, $direction ) = @_;

    # $from is a socket we can read from
    # low level read on the socket
    my $close = 0;
    my $buffer;
    my $read = $from->sysread( $buffer, $BUFFSIZE );

    # check for errors
    if ( not defined $read ) {
        warn sprintf( "Read undef from %s:%s (Error %d: %s)\n",
            $from->sockhost(), $from->sockport(), $!, "$!" );
        $close = 1;
    }

    # connection closed
    if ( $close || $read == 0 ) {
        $self->{sock}->close;
        Net::Proxy->remove_reader_sockets( $self->{sock} );
        delete $self->{sock};
        return Net::Proxy::Message->new( 'CONNECTION_CLOSED' );
    }

    # produce a DATA message
    return Net::Proxy::Message->new( DATA => { data => $buffer } );
}

sub CAN_WRITE {
    my ( $self, $message, $from, $direction ) = @_;

    # read from the buffer
    my $data = $self->{buffer};
    return if ! length $data;

    # write to the $from socket
    my $written = $from->syswrite( $data, $BUFFSIZE );

    if( ! defined $written ) {
        warn sprintf("Read undef from %s:%s (Error %d: %s)\n",
                     $from->sockhost(), $from->sockport(), $!, "$!");
    }
    elsif ( $written == length $data ) {
        Net::Proxy->remove_writer_sockets( $from );
        $self->{buffer} = undef;
    }
    else { # there is some data left to write
        $self->{buffer} = substr( $data, $written );
    }

    # no more message
    return;
}

sub DATA {
    my ( $self, $message, $from, $direction ) = @_;

    # simply buffer the data
    $self->{buffer} .= $message->{data};

    # connect to our peer if needed
    $self->{sock} ||= $self->connect_to_peer();

    # be ready to write
    Net::Proxy->watch_writer_sockets( $self->{sock} );

    # no more message
    return;
}

sub START_CONNECTION {
    my ( $self, $message, $from, $direction ) = @_;
    
    $self->{sock} = IO::Socket::INET->new(
        PeerAddr  => $self->{host},
        PeerPort  => $self->{port},
        Proto     => 'tcp',
        Timeout   => $self->{timeout},
    );

    # FIXME - send a message back
    die $! unless $self->{sock};

    # we will read/write data in the opposite direction
    Net::Proxy->set_compdir_for(
        $self->{sock} => $self,
        $self->opposite($direction)
    );
    Net::Proxy->watch_reader_sockets( $self->{sock} );

    return;
}

sub CONNECTION_CLOSED {
    my ( $self, $message, $from, $direction ) = @_;

    $self->{sock}->close;
    Net::Proxy->remove_reader_sockets( $self->{sock} );
    delete $self->{sock};

    return;
}

package Net::Proxy::ComponentFactory::tcp;

sub START_PROXY {
    my ( $self, $message, $from, $direction ) = @_;
    return if ! $self->{Listen};

    # FIXME - same options as IO::Socket::INET ?
    # pickup the args from $self ?
    $self->{sock} = IO::Socket::INET->new(
        Listen    => $self->{Listen},
        LocalAddr => $self->{host},
        LocalPort => $self->{port},
        Proto     => 'tcp',
        ReuseAddr => $^O eq 'MSWin32' ? 0 : 1,
    );

    # this exception is not catched by Net::Proxy
    die "Can't listen on $self->{host} port $self->{port}: $!"
        unless $self->{sock};

    # link the socket to us
    Net::Proxy->set_compdir_for( $self->{sock} => $self, $direction );
    Net::Proxy->watch_reader_sockets( $self->{sock} );

    # pass the message on
    return $message;
}

sub CAN_READ {
    my ( $self, $message, $from, $direction ) = @_;

    # return a ACCEPT message that will be passed to the component
    return Net::Proxy::Message->new( 'ACCEPT' );
}

1;

__END__

=head1 NAME

Net::Proxy::Component::tcp - Net::Proxy component for standard tcp proxies

=head1 SYNOPSIS

    # sample proxy using Net::Proxy::Component::tcp
    use Net::Proxy;

    my $chain = Net::Proxy->chain(
        { type => 'tcp', port => '6789', Listen => 1 },
        { type => 'tcp', host => 'remotehost', port => '9876' },
    );
    $chain->register();

    Net::Proxy->mainloop();

=head1 DESCRIPTION

C<Net::Proxy::Component::tcp> is a connector for handling basic, standard
TCP connections.

=head1 COMPONENT OPTIONS

The component accept the following options:

=over 4

=item * Listen

If set to a positive value, the component will create a listening socket.

=item * host

The listening or peer address. If not given, the default is C<localhost>.

=item * port

The port on which to listen or connect.

=back

=head1 AUTHOR

Philippe 'BooK' Bruhat, C<< <book@cpan.org> >>.

=head1 COPYRIGHT

Copyright 2008 Philippe 'BooK' Bruhat, All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

