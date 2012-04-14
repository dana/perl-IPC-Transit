use Module::Build;
#copied shamelessly from Pod-PseudoPod-0.18/Build.PL
my $build = Module::Build->new (
    module_name => 'IPC::Transit',
    license => 'perl',
    build_requires => {
        'Test::More'    => 0,
    },
    requires => {
        'IPC::SysV'        => 0,
        'IPC::Msg'         => 0,
        'POSIX'            => 0,
        'Data::Dumper'     => 0,
        'Data::Serializer' => 0,
    },
    recursive_test_files => 1,
    dist_author          => 'Dana M. Diederich <diederich@gmail.com>',
    dist_abstract        => 'A framework for high performance message passing',
);
$build->create_build_script;
