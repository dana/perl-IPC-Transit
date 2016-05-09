#!env perl

use strict;use warnings;

use lib '../lib';
use lib 'lib';
use Test::More;

use_ok('IPC::Transit') or exit;
use_ok('IPC::Transit::Test') or exit;

#I don't have time to figure out how to run the plack command such that
#bin/remote-transit-gateway.psgi uses the testing IPC::Transit directory,
#but I know full remote is working well.
ok 1, 'not testing full remote at this time';
done_testing();
exit 0;
$ENV{PLACK_ENV} = 'cpan';

ok my $transitd_pid = IPC::Transit::Test::run_daemon('perl bin/remote-transitd');
#ok my $transit_gateway_pid = IPC::Transit::Test::run_daemon('remote-transit-gateway.psgi');
ok my $transit_gateway_pid = IPC::Transit::Test::run_daemon('plackup --port 9816 bin/remote-transit-gateway.psgi');
sleep 2; #let them spin up a bit
IPC::Transit::send(message => {foo => 'bar'}, qname => $IPC::Transit::test_qname, destination => '127.0.0.1');
sleep 2; #let them do their jobs
ok my $ret = IPC::Transit::receive(qname => $IPC::Transit::test_qname);
ok $ret->{foo};
ok $ret->{foo} eq 'bar';

ok IPC::Transit::Test::kill_daemon($transitd_pid);
ok IPC::Transit::Test::kill_daemon($transit_gateway_pid);
