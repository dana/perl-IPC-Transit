#!env perl

use strict;use warnings;

use lib '../lib';
use lib 'lib';
use Test::More tests => 17;

use_ok('IPC::Transit') or exit;
use_ok('IPC::Transit::Router') or exit;
use_ok('IPC::Transit::Test') or exit;
IPC::Transit::Test::clear_test_queue();

ok not IPC::Transit::Router::config_trans();
{   my $config = {
        routes => [
            {   match => {
                    a => 'b',
                },
                forwards => [
                    {   qname => 'test',
                    }
                ]
            }
        ]
    };

    ok IPC::Transit::Router::config_trans($config)->{routes}->[0]->{match}->{a} eq 'b';
    ok IPC::Transit::Router::config_trans()->{routes}->[0]->{match}->{a} eq 'b';

    ok IPC::Transit::Router::_match({a => 'b', c => 'd'}, $config->{routes}->[0]->{match});
    ok not IPC::Transit::Router::_match({a => 'c', e => 'd'}, $config->{routes}->[0]->{match});
}

{   my $config = {
        routes => [
            {   match => {
                    a => 'b',
                    10 => 20,
                },
                forwards => [
                    {   qname => 'test',
                    }
                ]
            }
        ]
    };

    ok IPC::Transit::Router::config_trans($config)->{routes}->[0]->{match}->{a} eq 'b';
    ok IPC::Transit::Router::config_trans()->{routes}->[0]->{match}->{a} eq 'b';

    ok IPC::Transit::Router::_match({a => 'b', 10 => 20, hi => 'there'}, $config->{routes}->[0]->{match});
    ok IPC::Transit::Router::_match({a => 'b', 10 => '20', foo => 'bar'}, $config->{routes}->[0]->{match});
    ok not IPC::Transit::Router::_match({a => 'c', e => 'd'}, $config->{routes}->[0]->{match});
}

{   my $config = {
        routes => [
            {   match => {
                    a => 'b',
                },
                forwards => [
                    {   qname => 'test',
                    }
                ]
            }
        ]
    };

    ok IPC::Transit::Router::config_trans($config);
    ok IPC::Transit::Router::route_trans({a => 'b'});
    ok my $m = IPC::Transit::receive(qname => 'test', nonblock => 1);
    ok $m->{a} eq 'b';
}

__END__
{   my $simple_route = {
        routes => [
            {   match => {
                    a => 'b',
                },
                forwards => [
                    {   qname => 'test',
                    }
                ]
            }
        ]
    };

    ok IPC::Transit::Router::config_trans($simple_route)->{routes}->[0]->{match}->{a} eq 'b';
__END__
#clean out the queue if there's something in it
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
