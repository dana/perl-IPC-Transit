package IPC::Transit::Test::Example;

use strict;use warnings;
use Data::Dumper;
use IPC::Transit;
use POE;

sub
import {
    my $self = shift;
    my ($callpack, $callfile, $callline) = caller;
    my @EXPORT;
    if (@_) {
        @EXPORT = @_;
    }
    foreach my $sym (@EXPORT) {
        no strict 'refs';
        *{"${callpack}::$sym"} = \&{"IPC::Transit::Test::Example::$sym"};
    }
}

sub
recur {
    my %args = @_;

    $args{repeat} = 300 unless $args{repeat};
    $args{work} = sub { print "Somebody forgot to pass work\n"; } unless $args{work};
    POE::Session->create(
        inline_states => {
            _start => sub {$_[KERNEL]->delay(tick => 1);},
            tick => sub {
                $_[KERNEL]->delay(tick => $args{repeat});
                &{$args{work}}(\%args);
            },
            _child => sub { }, #ignore kids
        },
    );
}

1;
