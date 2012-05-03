package IPC::Transit::Router;

use strict;use warnings;
use IPC::Transit;

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
        *{"${callpack}::$sym"} = \&{"IPC::Transit::Router::$sym"};
    }
}

use vars qw(
    $config
);
sub
config_trans {
    my $new = shift;
    return $config unless $new;
    $config = $new;
    return $config;
}

sub
_match {
    my $message = shift; my $match = shift;
    while(my ($key, $value) = each %$match) {
        return 0 unless $message->{$key} eq $value;
    }
    return 1;
}

sub
route_trans {
    eval {
        my $message = shift or die 'message ref required';
        $config = {} unless $config;
        $config->{routes} = [] unless $config->{routes};
        foreach my $route (@{$config->{routes}}) {
            die 'route requires match' unless $route->{match};
            die 'route match must be a HASH ref'
                if not ref $route->{match} or ref $route->{match} ne 'HASH';
            die 'route requires at least one forward' unless $route->{forwards};
            die 'route forward must be an ARRAY ref'
                if not ref $route->{forwards} or ref $route->{forwards} ne 'ARRAY';
        }
    };
    die "IPC::Transit::Router::route_trans: $@\n" if $@;
    1;
}

1;

__END__


README

{   routes => [
        {   match => {
            },
            forwards => [
                {   qname => $q1,
                    hostname => $h1,
                    continue => [0|1],
                }
            ],
            changes => [

            ],
        },
    ]
}
