use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Glob 'bsd_glob';

my @components = map { /(\w+)\.pm$/; $1 ? $1 : () }
    grep {-f}
    bsd_glob( File::Spec->catdir(qw( blib lib Net Proxy Component *.pm )) );

my %required_args = (
    connect => {
        host       => 'localhost',
        port       => 8080,
        proxy_host => 'localhost',
    },
);

plan tests => 5 * @components;

for my $comp (@components) {

    use_ok("Net::Proxy::Component::$comp");

    for my $class (
        "Net::Proxy::Component::$comp",
        "Net::Proxy::ComponentFactory::$comp"
        )
    {
        my $obj;
        my @args = $required_args{$comp} || ();
        eval { $obj = $class->new(@args) };
        is( $@, '', "$class->new()" );
        isa_ok( $obj, $class );
    }
}

