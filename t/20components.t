use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Glob 'bsd_glob';

my @components = map { /(\w+)\.pm$/; $1 ? $1 : () }
    grep {-f}
    bsd_glob( File::Spec->catdir(qw( blib lib Net Proxy Component *.pm )) );

plan tests => 5 * @components;

for my $comp (@components) {

    use_ok("Net::Proxy::Component::$comp");

    for my $class (
        "Net::Proxy::Component::$comp",
        "Net::Proxy::ComponentFactory::$comp"
        )
    {
        my $obj;
        eval { $obj = $class->new() };
        is( $@, '', "$class->new()" );
        isa_ok( $obj, $class );
    }
}

