package IPC::Transit;

use strict;use warnings;
use Data::Dumper;
use IPC::Transit::Internal;
use IPC::Transit::Serialize;

use vars qw(
    $VERSION
    $config_file $config_dir
    $local_queues
);

$VERSION = '0.01';

my $log = sub {
    my $l = shift;
    open my $fh, '>>', '/tmp/transit.log';
    print $fh Dumper $l;
    close $fh;
};

sub
send {
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

    if($local_queues and $local_queues->{$qname}) {
        push @{$local_queues->{$qname}}, \%args;
        return \%args;
    }

    eval {
        $args{serialized_message} = IPC::Transit::Serialize::freeze(%args);
    };
    my $to_queue = IPC::Transit::Internal::_initialize_queue(%args);
    return $to_queue->snd(1,$args{serialized_message}, IPC::Transit::Internal::_get_flags('nonblocks'));
}

sub
stat {
    my %args;
    {   my @args = @_;
        die 'IPC::Transit::stat: even number of arguments required'
            if scalar @args % 2;
        %args = @args;
    }
    my $qname = $args{qname};
    if($local_queues and $local_queues->{$qname}) {
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

sub
receive {
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
    if($local_queues and $local_queues->{$qname}) {
        my $m = shift @{$local_queues->{$qname}};
        return $m->{message};
    }
    my $from_queue = IPC::Transit::Internal::_initialize_queue(%args);
    my $ret = $from_queue->rcv($args{serialized_data}, 1024000, 1, IPC::Transit::Internal::_get_flags('nowait'));
    return undef unless $args{serialized_data};
    eval {
        $args{message} = IPC::Transit::Serialize::thaw(%args);
    };
    return $args{message};
}

sub
local_queue {
    my %args;
    {   my @args = @_;
        die 'IPC::Transit::local_queue: even number of arguments required'
            if scalar @args % 2;
        %args = @args;
    }
    my $qname = $args{qname};
    $local_queues = {} unless $local_queues;
    $local_queues->{$qname} = [];
    return 1;
}

1;

__END__

=head1 NAME

IPC::Transit - A framework for high performance message passing

** DEVELOPER RELEASE **

=head1 SYNOPSIS

  use strict;
  use IPC::Transit;
  IPC::Transit::send(qname => 'test', message => { a => 'b' });

  #...the same or a different process on the same machine
  my $message = IPC::Transit::receive(qname => 'test');

=head1 DESCRIPTION

** DEVELOPER RELEASE **

This is a proof of concept.

The file and serialization will not be considered set until
version 0.1.  More to the point, they will DEFINITELY change
after this release.

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

=head1 stat
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


=head1 SEE ALSO

A zillion other queueing systems.

=head1 TODO

In process delivery.

Cross box delivery.

Queue handling facilities.

Much else

=head1 BUGS

Patches, flames, opinions, enhancement ideas are all welcome.

I am not satisfied with not supporting Windows, but it is considered
secondary.  I am open to the possibility of adding abstractions for this
kind of support as long as it doesn't greatly affect the primary goals.

=head1 COPYRIGHT

Copyright (c) 2012, Dana M. Diederich. All Rights Reserved.

=head1 LICENSE

This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)

=head1 AUTHOR

Dana M. Diederich <diederich@gmail.com>

=cut
