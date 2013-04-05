use 5.006;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'IPC-Transit';
all_from 'lib/IPC/Transit.pm';
author   q{Dana M. Diederich <diederich@gmail.com>};
license  'artistic2';

perl_version 5.006;

tests_recursive('t');

resources (
   homepage   => 'https://metacpan.org/module/IPC::Transit',
   #IRC        => 'irc://irc.perl.org/#IPC-Transit',
   license    => 'http://www.perlfoundation.org/artistic_license_2_0',
   repository => 'git://github.com/dana/perl-IPC-Transit.git',
   bugtracker => 'https://github.com/dana/perl-IPC-Transit/issues',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
);

requires (
    'Data::Dumper' => 0,
    'HTTP::Lite' => 0,
    'IPC::SysV' => 0,
    'IPC::Msg' => 0,
    'POSIX' => 0,
    'JSON' => 0,
    'Storable' => 0,
    'Getopt::Std' => 0,
    'HTTP::Server::Simple::CGI' => 0,
);

install_as_cpan;
auto_install;
WriteAll;
