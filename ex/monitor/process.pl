#!perl

use common::sense;
use IPC::Transit;
use IPC::Transit::Test::Example qw(recur);
use Data::Dumper;

recur(repeat => 1, work => sub {
    while(my $m = IPC::Transit::receive(qname => 'process', nonblock => 1)) {
        say Dumper $m;
    }
});

POE::Kernel->run();

