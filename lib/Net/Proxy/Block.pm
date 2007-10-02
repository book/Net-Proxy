package Net::Proxy::Block;

use strict;
use warnings;
use Scalar::Util qw( blessed );

use Net::Proxy::Node;
our @ISA = qw( Net::Proxy::Node );

sub build_instance_class {
    my ($class) = @_;
    my ($component) = $class =~ m/^Net::Proxy::Block::(.*)$/;

    # eval the factory building code
    eval << "FACTORY";
    package Net::Proxy::BlockInstance::$component;
    use Net::Proxy::BlockInstance;
    our \@ISA = qw( Net::Proxy::BlockInstance);
FACTORY

    return;
}

sub new {
    my ( $class, $args ) = @_;
    my $self = bless { %{ $args || {} } }, $class;
    $self->init() if $self->can('init');
    return $self;
}

sub process {
    my ( $self, $message, $from, $direction ) = @_;

    my $action = $message->type();
    if ( $self->can($action) ) {
        $message = $self->$action( $message, $from, $direction );
        $action = $message->type();    # $message might have changed
    }

    # START is passed from factory to factory
    if ( $action eq 'START' ) {
        my $next = $self->next($direction);
        $next->process( $message, $self, $direction )
            if blessed $next && $next->isa('Net::Proxy::Node');
        return;
    }

    # ABORT
    return if $action eq 'ABORT';

    # create a block instance
    my $class = ref $self;
    $class =~ s/^Net::Proxy::Block::/Net::Proxy::BlockInstance::/;
    my $block = $class->new($self);

    # link the block to the rest of the chain
    $from->set_next( $direction => $block )
        if blessed $from && $from->isa('Net::Proxy::Node');
    $block->set_next( $direction => $self->next($direction) );

    # pass the message on to the new block instance
    $block->process( $message, $self, $direction );

    return;
}

1;

__END__

=head1 NAME

Net::Proxy::Block - Base class for all Component factories

=head1 SYNOPSIS

=head1 DESCRIPTION

The C<Net::Proxy::Block> class is the base class for all
block factories.

When a chain is first created, it is actually a chain of factories.
When the first message is passed to the factory, it processes the message,
creates an actual C<Net::Proxy::BLockInstance> object, to which it passes the
processed message.

The new block is linked to the next factory in the chain.

=head1 METHODS

This base class provides a single method:

=over 4

=item process( $message, $from )

The default processing for any message. The message is processed by the
appropriate method (if any) and then a concrete block is created,
inserted in the chain linked to the actual sockets. The block then
receives the message.

The C<INIT> message is send to the next factory in the chain, instead
of a concrete block.

=head1 AUTHOR

=cut

