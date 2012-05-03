#!perl

use common::sense;
use IPC::Transit;
use IPC::Transit::Test::Example qw(recur);
use File::Slurp;
use Moose::Autobox;
use Sys::Hostname;

recur(repeat => 1, work => sub {
    my $text = read_file('/proc/loadavg') or die 'nothing in /proc/loadavg';
    if($text =~ /^.*?\s+.*?\s+.*?\s+(?<in_run_queue>\d+)\/(?<total_procs>\d+)/){
        IPC::Transit::send(
            qname => 'process',
            message => %+->merge({hostname => hostname, source => 'gather.pl'})
        );
    } else {
        die 'regex match failed';
    }
});

POE::Kernel->run();

__END__

1.36 1.14 0.79 2/385 6792
2/385 number of processes in run queue / total number of procs

