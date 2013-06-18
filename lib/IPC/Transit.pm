package IPC::Transit;

use strict;use warnings;
use 5.006;
use IPC::Transit::Internal;
use Storable;
use Data::Dumper;
use JSON;
use HTTP::Lite;

use vars qw(
    $VERSION
    $config_file $config_dir
    $local_queues
);

our $wire_header_arg_translate = {
    destination => 'd',
    compression => 'c',
    serializer => 's'
};
our $wire_header_args = {
    s => {  #serializer
        json => 1,
        yaml => 1,
        storable => 1,
        dumper => 1,
    },
    c => {  #compression
        zlib => 1,
        snappy => 1,
        none => 1
    },
    d => 1, #destination address
    t => 1, #hop TTL
    q => 1, #destination qname
};
our $std_args = {
    message => 1,
    qname => 1,
    nowait => 1,
};
$VERSION = '0.73';

sub send {
    my %args;
    {   my @args = @_;
        die 'IPC::Transit::send: even number of arguments required'
            if scalar @args % 2;
        %args = @args;
    }
    my $qname = $args{qname};
    die "IPC::Transit::send: parameter 'qname' required"
        unless $qname;
    die "IPC::Transit::send: parameter 'qname' must be a scalar"
        if ref $qname;
    my $message = $args{message};
    die "IPC::Transit::send: parameter 'message' required"
        unless $message;
    die "IPC::Transit::send: parameter 'message' must be a HASH reference"
        if ref $message ne 'HASH';
    $message->{'.ipc_transit_meta'} = {} unless $message->{'.ipc_transit_meta'};
    $message->{'.ipc_transit_meta'}->{send_ts} = time;
    if($args{destination}) {
        $args{destination_qname} = $args{qname};
        $args{qname} = 'transitd';
        $args{ttl} = 9 unless $args{ttl};
    }

    #begin the hard work of figuring out if this message should be sent as
    #local delivery or not.
    #overall default is to non-local delivery

    #the overrides in .ipc_transit_meta in the message takes precidence
    #over previous calls to ::local_queue and/or ::no_local_queue

    #insides of overrides, the force_local and force_non_local
    #take precidence over the default_to.

    #algo
    #1. absolute override goes to the invocation: override_local/
    #   override_non_local
    #2. next, look at force_* in the message.  If they conflict, then we go
    #   with force_non_local.
    #3. lacking any instructions there, we go with the default_to directive,
    #   if any, in the message
    #4. lacking that, we go with what's been set with ::local_queue and/or
    #  ::no_local_queue
    #5. And finally, non-local delivery


    #1a:
    return _deliver_non_local($qname, \%args) if $args{override_local};

    #1b:
    return _deliver_local($qname, \%args) if $args{override_non_local};

    #2a:
    if(     $message->{'.ipc_transit_meta'}->{overrides} and
            $message->{'.ipc_transit_meta'}->{overrides}->{force_non_local} and
            $message->{'.ipc_transit_meta'}->{overrides}->{force_non_local}->{$args{qname}}) {
        return _deliver_non_local($qname, \%args);
    }

    #2b:
    if(     $message->{'.ipc_transit_meta'}->{overrides} and
            $message->{'.ipc_transit_meta'}->{overrides}->{force_local} and
            $message->{'.ipc_transit_meta'}->{overrides}->{force_local}->{$args{qname}}) {
        return _deliver_local($qname, \%args);
    }

    #3a:
    if(     $message->{'.ipc_transit_meta'}->{overrides} and
            $message->{'.ipc_transit_meta'}->{overrides}->{default_to} and
            $message->{'.ipc_transit_meta'}->{overrides}->{default_to} eq 'local'
    ) {
        return _deliver_local($qname, \%args);
    }

    #3b:
    if(     $message->{'.ipc_transit_meta'}->{overrides} and
            $message->{'.ipc_transit_meta'}->{overrides}->{default_to} and
            $message->{'.ipc_transit_meta'}->{overrides}->{default_to} eq 'non-local'
    ) {
        return _deliver_non_local($qname, \%args);
    }

    #4:
    if(     $local_queues and
            $local_queues->{$qname}) {
        return _deliver_local($qname, \%args);
    }

    #5:
    return _deliver_non_local($qname, \%args);
}

sub _deliver_local {
    my ($qname, $args) = @_;
    push @{$local_queues->{$qname}}, $args;
    return $args;
}

sub _deliver_non_local {
    my ($qname, $args) = @_;
    my $to_queue = IPC::Transit::Internal::_initialize_queue(%$args);
    pack_message($args);
    return $to_queue->snd(1,$args->{serialized_wire_data}, IPC::Transit::Internal::_get_flags('nonblock'));
}

sub stats {
    my $info = IPC::Transit::Internal::_stats();
    return $info;
}
sub stat {
    my %args;
    {   my @args = @_;
        die 'IPC::Transit::stat: even number of arguments required'
            if scalar @args % 2;
        %args = @args;
    }
    my $qname = $args{qname};
    if(not $args{override_local} and $local_queues and $local_queues->{$qname}) {
        return {
            qnum => scalar @{$local_queues->{$qname}}
        };
    }
    die "IPC::Transit::stat: parameter 'qname' required"
        unless $qname;
    die "IPC::Transit::stat: parameter 'qname' must be a scalar"
        if ref $qname;
    my $info = IPC::Transit::Internal::_stat(%args);
}

sub receive {
    my %args;
    {   my @args = @_;
        die 'IPC::Transit::receive: even number of arguments required'
            if scalar @args % 2;
        %args = @args;
    }
    my $qname = $args{qname};

    die "IPC::Transit::receive: parameter 'qname' required"
        unless $qname;
    die "IPC::Transit::receive: parameter 'qname' must be a scalar"
        if ref $qname;
    if(not $args{override_local} and $local_queues and $local_queues->{$qname}) {
        my $m = shift @{$local_queues->{$qname}};
        return $m->{message};
    }
    my $flags = 0;
    $flags = IPC::Transit::Internal::_get_flags('nowait') if $args{nonblock};
    my $from_queue = IPC::Transit::Internal::_initialize_queue(%args);
    my $serialized_wire_data;
    $from_queue->rcv($serialized_wire_data, 10240000, 0, $flags);
    return undef unless $serialized_wire_data;
    my $message = {
        serialized_wire_data => $serialized_wire_data,
    };
    unpack_data($message);
    if($message->{message}->{'.ipc_transit_meta'} and $message->{message}->{'.ipc_transit_meta'}->{destination_qname}) {
        #this message is destined for a queue that is different
        #than the one it landed on. Most likely a remote transit
        #this means that we are likely running inside remote-transitd, and
        #we need to post out
        return post_remote($message);
    }
    if($args{raw}) {
        return $message;
    } else {
        return $message->{message};
    }
}

sub post_remote {
    #This is very simple, first-generation logic.  It assumes that every
    #message that is received that has a qname set is destined for off box.

    #so here, we want to post this message to the destination over http
    my $message = shift;
    my $http = HTTP::Lite->new;
    my $vars = {
        message => $message->{serialized_wire_data},
    };
    $http->prepare_post($vars);
    my $url = 'http://' . $message->{message}->{'.ipc_transit_meta'}->{destination} . ':9816/message';
    my $req = $http->request($url)
        or die "Unable to get document: $!";
    return $req;
}

sub no_local_queue {
    my %args;
    {   my @args = @_;
        die 'IPC::Transit::no_local_queue: even number of arguments required'
            if scalar @args % 2;
        %args = @args;
    }
    my $qname = $args{qname};
    delete $local_queues->{$qname};
    return 1;
}

sub local_queue {
    my %args;
    {   my @args = @_;
        die 'IPC::Transit::local_queue: even number of arguments required'
            if scalar @args % 2;
        %args = @args;
    }
    my $qname = $args{qname};
    $local_queues = {} unless $local_queues;
    $local_queues->{$qname} = [] unless $local_queues->{$qname};
    return 1;
}

sub pack_message {
    my $args = shift;
    $args->{message}->{'.ipc_transit_meta'} = {}
        unless $args->{message}->{'.ipc_transit_meta'};
    foreach my $key (keys %$wire_header_arg_translate) {
        next unless $args->{$key};
        $args->{$wire_header_arg_translate->{$key}} = $args->{$key};
    }
    foreach my $key (keys %$args) {
        next if $wire_header_args->{$key};
        next if $std_args->{$key};
        $args->{message}->{'.ipc_transit_meta'}->{$key} = $args->{$key};
    }
    $args->{serialized_message} = freeze($args);
    serialize_wire_meta($args);
    my $l = length $args->{serialized_wire_meta_data};
    $args->{serialized_wire_data} = "$l:$args->{serialized_wire_meta_data}$args->{serialized_message}";
    return $args->{serialized_wire_data};
}

sub unpack_data {
    my $args = shift;
    my ($length, $header_and_message);
    my $s = $args->{serialized_wire_data};
    if($s =~ s/^(\d+)://) {
        $length = $1;
        $header_and_message = $s;
    } else {
        die 'passed serialized_wire_data malformed';
    }
    $args->{serialized_header} = substr($header_and_message, 0, $length, '');
    $args->{serialized_message} = $header_and_message;
    deserialize_wire_meta($args);
    thaw($args);
    return $args;
}

sub serialize_wire_meta {
    my $args = shift;
    my $s = '';
    foreach my $key (keys %$args) {
        my $translated_key = $wire_header_arg_translate->{$key};
        if($translated_key and $wire_header_args->{$translated_key}) {
            if($wire_header_args->{$translated_key} == 1) {
                $s = "$s$translated_key=$args->{$key},";
            } elsif($wire_header_args->{$translated_key}->{$args->{$key}}) {
                $s = "$s$translated_key=$args->{$key},";
            } else {
                die "passed wire argument $translated_key had value of $args->{$translated_key} not of allowed type";
            }
        }
    }
    chop $s; #no trailing ,
    $args->{serialized_wire_meta_data} = $s;
}

sub deserialize_wire_meta {
    my $args = shift;
    my $h = $args->{serialized_header};
    my $ret = {};
    foreach my $part (split ',', $h) {
        my ($key, $val) = split '=', $part;
        $ret->{$key} = $val;
    }
    $args->{wire_headers} = $ret;
}

sub freeze {
    my $args = shift;
    if(not defined $args->{serializer} or $args->{serializer} eq 'json') {
        return encode_json $args->{message};
    } elsif($args->{serializer} eq 'dumper') {
        return Data::Dumper::Dumper $args->{message};
    } elsif($args->{serializer} eq 'storable') {
        return Storable::freeze $args->{message};
    } else {
        die "freeze: undefined serializer: $args->{serializer}";
    }
}

sub thaw {
    my $args = shift;
    if(not defined $args->{wire_headers}->{s} or $args->{wire_headers}->{s} eq 'json') {
        return $args->{message} = decode_json($args->{serialized_message});
    } elsif($args->{wire_headers}->{s} eq 'dumper') {
        our $VAR1;
        eval $args->{serialized_message};
        return $args->{message} = $VAR1;
    } elsif($args->{wire_headers}->{s} eq 'storable') {
        return $args->{message} = Storable::thaw($args->{serialized_message});
    } else {
        die "thaw: undefined serializer: $args->{wire_headers}->{s}";
    }
}
1;

__END__

=head1 NAME

IPC::Transit - A framework for high performance message passing

=head1 NOTES

This module is wire incompatable with previous releases.  The wire
protocol in 0.4 and before was meant as a prototype and naive.

This is the final wire protocol.

The serialization is currently hard-coded to JSON.

=head1 SYNOPSIS

  use strict;
  use IPC::Transit;
  IPC::Transit::send(qname => 'test', message => { a => 'b' });

  #...the same or a different process on the same machine
  my $message = IPC::Transit::receive(qname => 'test');

  #remote transit
  remote-transitd &  #run 'outgoing' transitd gateway
  IPC::Transit::send(qname => 'test', message => { a => 'b' }, destination => 'some.other.box.com');

  #On 'some.other.box.com':
  remote-transit-gateway &  #run 'incoming' transitd gateway
  my $message = IPC::Transit::receive(qname => 'test');

=head1 DESCRIPTION

This queue framework has the following goals:
    
=over 4

=item * Serverless

=item * High Throughput

=item * Usually Low Latency

=item * Relatively Good Reliability

=item * CPU and Memory efficient

=item * Cross UNIX Implementation

=item * Multiple Language Compability

=item * Very few module dependencies

=item * Supports old version of Perl

=item * Feature stack is modular and optional

=back

This queue framework has the following anti-goals:

=over 4

=item * Guaranteed Delivery

=back

=head1 FUNCTIONS

=head2 send(qname => 'some_queue', message => $hashref, serializer => 'some serializer')

This sends $hashref to 'some_queue'.  some_queue may be on the local
box, or it may be in the same process space as the caller.

This call will block until the destination queue has enough space to
handle the serialized message.

The serialize_with argument is optional, and defaults to Data::Dumper.
Currently, we are using the module Data::Serializer::Raw; any serialization
scheme that module supports can be used here.

NB: there is no need to define the serialization type in receive.  It is
automatically detected and utilized.

=head2 receive(qname => 'some_queue', nonblock => [0|1], override_local => [0|1])

This function fetches a hash reference from 'some_queue' and returns it.
By default, it will block until a reference is available.  Setting nonblock
to a true value will cause this to return immediately with 'undef' is
no messages are available.

override_local defaults to false; if set to true, the receive will always
do a non-process local receive.


=head2 stat(qname => 'some_queue')

Returns various stats about the passed queue name, per IPC::Msg::stat:

 print Dumper IPC::Transit::stat(qname => 'test');
 $VAR1 = {
          'ctime' => 1335141770,
          'cuid' => 1000,
          'lrpid' => 0,
          'uid' => 1000,
          'lspid' => 0,
          'mode' => 438,
          'qnum' => 0,
          'cgid' => 1000,
          'rtime' => 0,
          'qbytes' => 16384,
          'stime' => 0,
          'gid' => 1000
 }

=head2 stats()

Return an array of hash references, each containing the information 
obtained by the stat() call, one entry for each queue on the system.

=head1 SEE ALSO

A zillion other queueing systems.

=head1 TODO

Crypto

much else

=head1 BUGS

Patches, flames, opinions, enhancement ideas are all welcome.

I am not satisfied with not supporting Windows, but it is considered
secondary.  I am open to the possibility of adding abstractions for this
kind of support as long as it doesn't greatly affect the primary goals.

=head1 COPYRIGHT

Copyright (c) 2012, 2013 Dana M. Diederich. All Rights Reserved.

=head1 LICENSE

This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)

=head1 AUTHOR

Dana M. Diederich <diederich@gmail.com>

=cut
