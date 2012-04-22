package IPC::Transit::Internal;

use strict;
use IPC::SysV;
use IPC::Msg;
use POSIX;


use vars qw(
    $config
);

{
my $queue_cache = {};
sub
_initialize_queue {
    my %args = @_;
    my $qid = _get_queue_id(%args);
    if(not $queue_cache->{$qid}) {
        $queue_cache->{$qid} = IPC::Msg->new($qid, _get_flags('create_ipc'))
            or die "failed to _initialize_queue: failed to create queue_id $qid: $!\n";
    }
    return $queue_cache->{$qid};
}
}

sub
_get_transit_config_file {
    my $cf = $IPC::Transit::config_file || 'transit.conf';
    my $dir = $IPC::Transit::config_dir || '/tmp/';
    return "$dir/$cf";
}

sub
_lock_config_file {
    my $lock_file = _get_transit_config_file() . '.lock';
    my ($have_lock, $fh);
    for (1..10) {
        if(sysopen($fh, $lock_file, _get_flags('exclusive_lock'))) {
            $have_lock = 1;
            last;
        }
        sleep 1;
    }
    if(not $have_lock) {
        _unlock_config_file();
        sysopen($fh, $lock_file, _get_flags('exclusive_lock'));
    }
    #we have the advisory lock for sure now
}


sub
_unlock_config_file {
    my $lock_file = _get_transit_config_file() . '.lock';
    unlink $lock_file or die "_unlock_config_file: failed to unlink $lock_file: $!";
}

sub
_load_transit_config {
    my $cf = _get_transit_config_file();
    if(not -r $cf) {
        my $previous_umask = umask 0000;
        open my $fh, '>', $cf or die "failed to open '$cf' for writing: $!\n";
        print $fh '' or die "failed to write to '$cf': $!\n";
        close $fh or die "failed to close '$cf': $!";
        umask $previous_umask;
    }
    my $queues = {};
    open my $fh, '<', $cf or die "failed to open '$cf' for writing: $!\n";
    while(my $line = <$fh>) {
        chomp $line;
        my ($qname, $qid, @others) = split ':', $line;
        $queues->{$qname} = { qid => $qid, @others };
    }
    close $fh or die "failed to close '$cf': $!";
    $config->{queues} = $queues;
    return $config;
}

sub
_write_transit_config {
    my $cf = _get_transit_config_file();
    my $previous_umask = umask 0000;
    _lock_config_file();
    eval {
        open my $fh, '>', $cf or die "failed to open '$cf' for writing: $!\n";
        while (my($qname, $rec) = each %{$config->{queues}}) {
            print $fh "$qname:$rec->{qid}\n" or die "failed to write to '$cf': $!\n";
        }
        close $fh or die "failed to close '$cf': $!";
    };
    _unlock_config_file();
    umask $previous_umask;
    die "_write_transit_config failed: $@\n" if $@;
    return $config;
}


sub
_get_queue_id {
    my %args = @_;
    my $qname = $args{qname};
    return $config->{queues}->{$qname}->{qid}
        if $config->{queues} and $config->{queues}->{$qname};

    _lock_config_file();
    eval {
        _load_transit_config();
        if($config->{queues} and $config->{queues}->{$qname}) {
            _unlock_config_file();
            return $config->{queues}->{$qname}->{qid};
        }
        my $next_number;
        if(scalar keys %{$config->{queues}}) {
            {   my @current_numbers = sort {$a <=> $b} values %{$config->{queues}};
                my $highest_number = pop @current_numbers;
                $next_number = $highest_number++;
            }
        } else {
            #$config->{queues}->{$qname} = { qid => 1 };
            $next_number = 1;
        }
        $config->{queues}->{$qname} = { qid => $next_number };
        _unlock_config_file();
        _write_transit_config();
    };

    _unlock_config_file();
    return $config->{queues}->{$qname}->{qid};
}

#gnarly looking UNIX goop hidden below
{
my $flags = {
    create_ipc =>       IPC::SysV::S_IRUSR() |
                        IPC::SysV::S_IWUSR() |
                        IPC::SysV::S_IRGRP() |
                        IPC::SysV::S_IWGRP() |
                        IPC::SysV::S_IROTH() |
                        IPC::SysV::S_IWOTH() |
                        IPC::SysV::IPC_CREAT(),

    nowait =>           IPC::SysV::IPC_NOWAIT(),

    exclusive_lock =>   POSIX::O_RDWR() |
                        POSIX::O_CREAT() |
                        POSIX::O_EXCL(),

    nonblock =>         POSIX::O_NONBLOCK(),
};

sub
_get_flags {
    my $name = shift;
    return $flags->{$name};
}
}
1;
