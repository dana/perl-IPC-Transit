#!env perl

use strict;use warnings;

use lib '../lib';
use lib 'lib';
use Test::More tests => 4;

use_ok('IPC::Transit') or exit;
use_ok('IPC::Transit::Test') or exit;

#clean out the queue if there's something in it
IPC::Transit::Test::clear_test_queue();
eval {
    local $SIG{ALRM} = sub { die "timed out\n" };
    alarm 1;
    IPC::Transit::receive(qname => 'test');
    alarm 0;
};
ok $@;
ok $@ eq "timed out\n";
