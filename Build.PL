use Module::Build;
my $build = Module::Build->new(
    module_name => 'Net::Proxy',
    license     => 'perl',
    requires    => {
        'perl'         => '5.6',
        'Scalar::Util' => 0,
        'IO::Select'   => 0,
        'IO::Socket'   => 0,
    },
);
$build->create_build_script;

