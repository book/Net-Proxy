package Net::Proxy::Block;

use strict;
use warnings;
use Scalar::Util qw( blessed );

use Net::Proxy::Node;
our @ISA = qw( Net::Proxy::Node );

#
# CLASS METHODS
#
sub build_instance_class {
    my ($class) = @_;
    my ($component) = $class =~ m/^Net::Proxy::Block::(.*)$/;

    # eval the factory building code
    eval << "FACTORY";
    package Net::Proxy::BlockInstance::$component;
    use Net::Proxy::BlockInstance;
    our \@ISA = qw( Net::Proxy::BlockInstance );
FACTORY
    die $@ if $@;

    return;
}

sub new {
    my ( $class, $args ) = @_;
    my $self = bless { %{ $args || {} } }, $class;
    $self->init() if $self->can('init');
    return $self;
}

#
# INSTANCE METHODS
#
sub process {
    my ( $self, $messages, $from, $direction ) = @_;

    # let the mixin class process the messages
    $self->act_on( $messages, $from, $direction );

    # create a block instance
    my $class = ref $self;
    $class =~ s/^Net::Proxy::Block::/Net::Proxy::BlockInstance::/;
    my $block = $class->new($self);

    # link the block to the rest of the chain
    $from->set_next( $direction => $block )
        if blessed $from && $from->isa('Net::Proxy::Node');
    $block->set_next( $direction => $self->next($direction) );

    # pass the message on to the new block instance
    $block->process( $messages, $self, $direction );

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

This base class provides several methods:

=over 4

=item build_instance_class()

This method automatically intialize the corresponding C<BlockInstance>
associated with the C<Block> class. This simplifies the writing of
C<Block>/C<BlockInstance> classes, and allows the author to have a
single F<.pm> file where message-handling methods are stored for both
classes.

=item new( $args )

Return a new C<Net::Proxy::Block> object, initialized with the content
of the C<$args> hashref.

=item process( $messages, $from, $direction )

The default processing for a message stack. The messages are processed
by the appropriate method (if any) and then a concrete block is
created, inserted in the chain linked to the actual sockets (in the
proper C<$direction>). The block then receives the message stack and
processes it.

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book@cpan.org> >>.

=head1 COPYRIGHT

Copyright 2007 Philippe Bruhat (BooK), All Rights Reserved.
 
=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

