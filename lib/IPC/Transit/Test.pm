package IPC::Transit::Test;

use strict;use warnings;
use Data::Dumper;
use IPC::Transit;

BEGIN {
    $IPC::Transit::config_file = "transit_test_$$.conf";
};
sub
clear_test_queue {
    for(1..100) {
        my $m;
        eval {
            $m = IPC::Transit::receive(qname => 'test', nonblock => 1);
        };
        last if $m;
    }
}

END {
    unlink "/tmp/$IPC::Transit::config_file";
    IPC::Transit::Internal::_drop_all_queues();
};
1;
