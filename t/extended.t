#!env perl

use strict;use warnings;

use lib '../lib';
use lib 'lib';
use Test::More tests => 14;

use_ok('IPC::Transit') or exit;
use_ok('IPC::Transit::Test') or exit;

#clean out the queue if there's something in it
IPC::Transit::Test::clear_test_queue();
ok IPC::Transit::send(qname => 'test', message => { a => 'b' });
ok my $m = IPC::Transit::receive(qname => 'test');
ok $m->{a} eq 'b';
ok not $m->{'.transit'};
ok IPC::Transit::send(qname => 'test', message => { a => 'b' });
ok $m = IPC::Transit::receive(qname => 'test', extended => 1);
ok $m->{a} eq 'b';
ok $m->{'.transit'};
ok ref $m->{'.transit'};
ok ref $m->{'.transit'} eq 'HASH';
ok $m->{'.transit'}->{send_ts};
ok $m->{'.transit'}->{send_ts} =~ /^\d+$/;
