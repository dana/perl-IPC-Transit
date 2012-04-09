package IPC::Transit::Serialize;

use strict;use warnings;
use Data::Dumper;
use Data::Serializer::Raw;

my $serializer = Data::Serializer::Raw->new(
    serializer => 'Data::Dumper',
    options => {},
);
sub
freeze {
    my %args;
    {   my @args = @_;
        die 'IPC::Transit::Serialize::freeze: even number of arguments required'
            if scalar @args % 2;
        %args = @args;
    }
    my $serialized_data = $serializer->serialize($args{message});
    return $serialized_data;
}

sub
thaw {
    my %args;
    {   my @args = @_;
        die 'IPC::Transit::Serialize::thaw: even number of arguments required'
            if scalar @args % 2;
        %args = @args;
    }
    my $s = $args{serialized_data};
    eval {
        $args{message} = $serializer->deserialize($s);
    };
    return $args{message};
}

1;
