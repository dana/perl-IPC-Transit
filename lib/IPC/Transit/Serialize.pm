package IPC::Transit::Serialize;

use strict;use warnings;
use Data::Serializer::Raw;

our $serializers = {
    'Data::Dumper' => Data::Serializer::Raw->new(
        serializer => 'Data::Dumper',
        options => {},
    ),
};
sub
freeze {
    my %args;
    {   my @args = @_;
        die 'IPC::Transit::Serialize::freeze: even number of arguments required'
            if scalar @args % 2;
        %args = @args;
    }
    my $serialize_with = $args{serialize_with} || 'Data::Dumper';
    if(not $serializers->{$serialize_with}) {
        $serializers->{$serialize_with} = Data::Serializer::Raw->new(
            serializer => $serialize_with
        );
    }
    my $serialized_data = $serialize_with . '/' . $serializers->{$serialize_with}->serialize($args{message});
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
    my ($serialize_with, @serialized_data) = split '\/', $args{serialized_data};
    my $serialized_data = join '/', @serialized_data;
    eval {
        $args{message} = $serializers->{$serialize_with}->deserialize($serialized_data);
    };
    return $args{message};
}

1;
