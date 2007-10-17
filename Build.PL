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
    recommends         => { 'LWP::UserAgent' => 2, 'IO::Socket::SSL' => 1 },
    script_files       => [ glob 'script/*' ],
    add_to_cleanup     => ['Net-Proxy-*'],
);
$build->create_build_script();

