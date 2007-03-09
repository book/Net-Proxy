use Test::More;
use File::Find;

my %prereqs = ( 'Net::Proxy::Connector::ssl' => [qw( IO::Socket::SSL )], );

# compute the list of modules
my @modules;
find( sub { push @modules, $File::Find::name if /\.pm$/ }, 'blib/lib' );
@modules = sort map { s!/!::!g; s/\.pm$//; s/^blib::lib:://; $_ } @modules;

plan tests => scalar @modules;

for my $module (@modules) {
SKIP: {
        my $missing_prereqs = 0;

        for my $prereq ( @{ $prereqs{$module} } ) {
            eval "require $prereq";
            $missing_prereqs++ if $@;
        }
        skip "Missing prerequisites for $module", 1 if $missing_prereqs;
        use_ok($module);
    }
}

