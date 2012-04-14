package IPC::Transit::Test;

use strict;use warnings;
use Data::Dumper;
use IPC::Transit;

sub
clear_test_queue {
    for(1..100) {
        my $m;
        eval {
            $m = IPC::Transit::receive(qname => 'test');
        };
        last if $m;
    }
}

1;
