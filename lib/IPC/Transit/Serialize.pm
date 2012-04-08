package IPC::Transit::Serialize;

use strict;use warnings;
use Data::Dumper;

sub
freeze {
    my %args;
    {   my @args = @_;
        die 'IPC::Transit::Serialize::freeze: even number of arguments required'
            if scalar @args % 2;
        %args = @args;
    }
    return Dumper $args{message};
}

sub
thaw {
    my %args;
    {   my @args = @_;
        die 'IPC::Transit::Serialize::thaw: even number of arguments required'
            if scalar @args % 2;
        %args = @args;
    }
    eval {
        my $VAR1;
        eval $args{serialized_data};
        $args{message} = $VAR1;
    };
    return $args{message};
}

1;
