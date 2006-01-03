use Test::More tests => 3;
use strict;
use warnings;
use Net::Proxy::Multiplexer;

#
# dummy Net::Proxy object
#
package Net::Proxy::Test;

use Net::Proxy;
our @ISA = qw( Net::Proxy );

sub init {
    Test::More::ok( 1, "Init called for " . shift );
    return; # return nothing
}

package main;

my $arg = { type => 'tcp' };

my $proxy  = Net::Proxy::Test->new( { in => $arg, out => $arg } );
my $proxy2 = Net::Proxy::Test->new( { in => $arg, out => $arg } );

# register the proxy objects
Net::Proxy::Multiplexer->register_proxy( $proxy );
$proxy2->register();

# test the proxy initialisation
Net::Proxy::Multiplexer->mainloop();

# remove one of the proxies
Net::Proxy::Multiplexer->unregister_proxy( $proxy2 );
Net::Proxy::Multiplexer->mainloop();
