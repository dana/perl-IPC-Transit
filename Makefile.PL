use ExtUtils::MakeMaker;

#copied shamelessly from Pod-PseudoPod-0.18/Makefile.PL
# The list of tests has to be explicitly generated on Win98.
my @tests;
for my $dir (qw(t)) {
    opendir TESTS, $dir or die $!;
    push @tests, map { "$dir/$_" } grep { /\.t$/ } readdir TESTS;
    closedir TESTS;
}

WriteMakefile(
    NAME         => 'IPC::Transit',
    VERSION_FROM => 'lib/IPC/Transit.pm', # finds $VERSION
    PREREQ_PM    => {
        'IPC::SysV'       => 0,
        'IPC::Msg'        => 0,
        'POSIX'           => 0,
        'Data::Dumper'    => 0,
    },
    test =>
        {TESTS => "@tests"},
    AUTHOR       => 'Dana M. Diederich <diederich@gmail.com>',
    ABSTRACT     => 'A framework for high performance message passing',
    PL_FILES => {}, # ignore the Build.PL file
);
