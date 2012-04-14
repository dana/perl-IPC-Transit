#!env perl

use strict;use warnings;

use lib '../lib';
use lib 'lib';
use Test::More tests => 65;

use_ok('IPC::Transit') or exit;
use_ok('IPC::Transit::Test') or exit;

#clean out the queue if there's something in it
IPC::Transit::Test::clear_test_queue();
ok IPC::Transit::send(qname => 'test', message => { a => 'b' }, serialize_with => 'Storable');
ok my $m = IPC::Transit::receive(qname => 'test');
ok $m->{a} eq 'b';

for(1..20) {
    ok IPC::Transit::send(qname => 'test', message => { a => $_ }, serialize_with => 'Storable');
}
foreach my $ct (1..20) {
    ok my $m = IPC::Transit::receive(qname => 'test');
    ok $m->{a} == $ct;
}
