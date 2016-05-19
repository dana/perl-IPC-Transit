# NAME

IPC::Transit - A framework for high performance message passing

# NOTES

The serialization is currently hard-coded to https://metacpan.org/pod/Sereal

# SYNOPSIS

    use strict;
    use IPC::Transit;
    IPC::Transit::send(qname => 'test', message => { a => 'b' });

    #...the same or a different process on the same machine
    my $message = IPC::Transit::receive(qname => 'test');

    #remote transit
    remote-transitd &  #run 'outgoing' transitd gateway
    IPC::Transit::send(qname => 'test', message => { a => 'b' }, destination => 'some.other.box.com');

    #On 'some.other.box.com':
    plackup --port 9816 $(which remote-transit-gateway.psgi) &  #run 'incoming' transitd gateway
    my $message = IPC::Transit::receive(qname => 'test');

# DESCRIPTION

This queue framework has the following goals:

- Serverless
- High Throughput
- Usually Low Latency
- Relatively Good Reliability
- CPU and Memory efficient
- Cross UNIX Implementation
- Multiple Language Compability
- Very few module dependencies
- Supports old version of Perl
- Feature stack is modular and optional

This queue framework has the following anti-goals:

- Guaranteed Delivery

# FUNCTIONS

## send(qname => 'some\_queue', message => $hashref, \[destination => $destination, serializer => 'some serializer', crypto => 1 \])

This sends $hashref to 'some\_queue'.  some\_queue may be on the local
box, or it may be in the same process space as the caller.

This call will block until the destination queue has enough space to
handle the serialized message.

The destination argument is optional.  If defined, it is the remote host
will receive the message.

The serialize argument is optional, and defaults to Sereal.  It is
over-ridden with the IPC\_TRANSIT\_DEFAULT\_SERIALIZER environmental
variable.  The following serializers are available:

serial, json, yaml, storable, dumper

NB: there is no need to define the serialization type in receive.  It is
automatically detected and utilized.

The crypto argument is optional.  See below for details.

## receive(qname => 'some\_queue', nonblock => \[0|1\], override\_local => \[0|1\])

This function fetches a hash reference from 'some\_queue' and returns it.
By default, it will block until a reference is available.  Setting nonblock
to a true value will cause this to return immediately with 'undef' is
no messages are available.

override\_local defaults to false; if set to true, the receive will always
do a non-process local receive.

## stat(qname => 'some\_queue')

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

## stats()

Return an array of hash references, each containing the information 
obtained by the stat() call, one entry for each queue on the system.

## CRYPTO

On send(), if the crypto argument is set, IPC::Transit will sign and
encrypt the message before it is sent.  The necessary configs, including
relevant keys, are set in some global variables.

See an actual example of this in action under ex/crypto.pl

Please note that this module does not directly assist with the always
onerous task of key distribution.

### $IPC::Transit::my\_hostname

If not set, this defaults to the output of the module Sys::Hostname.
This value is placed into the message by the sender, and used by the
receiver to lookup the public key of the sender.

### $IPC::Transit::my\_keys

This is a hash reference initially populated, in the attribute 'default',
with the private half of a default key pair.  For actual secure
communication, a new key pair must be generated on both sides, and the
sender's private key needs to be placed here:

    $IPC::Transit::my_keys->{private} = $real_private_key

### $IPC::Transit::public\_keys

As above, this is a hash reference initially populated, in the attribute
'default', with the public half of a default key pair.  For actual secure
communication, a new key pair must be generated on both sides, and the
receiver's public key needs to be placed here:

    $IPC::Transit::public_keys->{$receiver_hostname} = $real_public_key_from_receiver

$receiver\_hostname must exactly match what is passed into the 'destination'
field of send().

All of these keys must be base 64 encoded 32 byte primes, as used by
the Crypto::Sodium package.

### IPC::Transit::gen\_key\_pair()

This returns a two element array representing a public/privte key pair,
properly base64 encoded for use in $IPC::Transit::my\_keys and
$IPC::Transit::public\_keys

# SEE ALSO

A zillion other queueing systems.

# TODO

Implement nonblock flag for send()

# BUGS

Patches, flames, opinions, enhancement ideas are all welcome.

I am not satisfied with not supporting Windows, but it is considered
secondary.  I am open to the possibility of adding abstractions for this
kind of support as long as it doesn't impact the primary goals.

# COPYRIGHT

Copyright (c) 2012, 2013, 2016 Dana M. Diederich. All Rights Reserved.

# LICENSE

This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)

# AUTHOR

Dana M. Diederich <dana@realms.org>
