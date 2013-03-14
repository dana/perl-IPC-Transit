#!env perl

use strict;use warnings;

use lib '../lib';
use lib 'lib';
use Test::More tests => 9;

use_ok('IPC::Transit') or exit;
use_ok('IPC::Transit::Test') or exit;

ok my $transitd_pid = IPC::Transit::Test::run_daemon('remote-transitd');
ok my $transit_gateway_pid = IPC::Transit::Test::run_daemon('remote-transit-gateway');
sleep 2; #let them spin up a bit
IPC::Transit::send(message => {foo => 'bar'}, qname => $IPC::Transit::test_qname, destination => '127.0.0.1');
sleep 2; #let them do their jobs
ok my $ret = IPC::Transit::receive(qname => $IPC::Transit::test_qname);
ok $ret->{foo};
ok $ret->{foo} eq 'bar';

ok IPC::Transit::Test::kill_daemon($transitd_pid);
ok IPC::Transit::Test::kill_daemon($transit_gateway_pid);
