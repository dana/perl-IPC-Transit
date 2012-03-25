#!env perl

use strict;use warnings;

use lib '../lib';
use lib 'lib';
use Test::More tests => 64;

use_ok('IPC::Transit') or exit;

#clean out the queue if there's something in it
for(1..100) {
    my $m;
    eval {
        $m = IPC::Transit::receive(qname => 'test');
    };
    last if $m;
}
ok IPC::Transit::send(qname => 'test', message => { a => 'b' });
ok my $m = IPC::Transit::receive(qname => 'test');
ok $m->{a} eq 'b';

for(1..20) {
    ok IPC::Transit::send(qname => 'test', message => { a => $_ });
}
foreach my $ct (1..20) {
    ok my $m = IPC::Transit::receive(qname => 'test');
    ok $m->{a} == $ct;
}
