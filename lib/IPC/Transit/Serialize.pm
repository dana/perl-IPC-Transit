package IPC::Transit::Serialize;

use strict;use warnings;

sub
freeze {
    my %args;
    {   my @args = @_;
        die 'IPC::Transit::Serialize::freeze: even number of arguments required'
            if scalar @args % 2;
        %args = @args;
    }

}

sub
thaw {
    my %args;
    {   my @args = @_;
        die 'IPC::Transit::Serialize::thaw: even number of arguments required'
            if scalar @args % 2;
        %args = @args;
    }

}

1;
