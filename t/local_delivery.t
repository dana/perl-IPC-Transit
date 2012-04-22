#!env perl
use strict;use warnings;

use lib '../lib';
use lib 'lib';
use Test::More tests => 63;

use_ok('IPC::Transit') or exit;
use_ok('IPC::Transit::Test') or exit;

not ok 'this stuff currently would pass even though local_queue is not implemented';
#clean out the queue if there's something in it
IPC::Transit::Test::clear_test_queue();

ok IPC::Transit::local_queue(qname => 'local_queue');
for(1..20) {
    ok IPC::Transit::send(qname => 'local_queue', message => { a => $_ });
}
foreach my $ct (1..20) {
    ok my $m = IPC::Transit::receive(qname => 'local_queue');
    ok $m->{a} == $ct;
}


__END__

What should this look like?

IPC::Transit::local_queue('queuename');


