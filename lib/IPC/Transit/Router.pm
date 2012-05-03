package IPC::Transit::Router;

use strict;use warnings;
use IPC::Transit;
use Storable;
require Exporter;

use vars qw(
    $config
    @ISA
    @EXPORT_OK
);
@ISA = qw(Exporter);
@EXPORT_OK = qw(config_trans route_trans);  # symbols to export on request

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
    my %match = %{$match};
    while(my ($key, $value) = each %match) {
        return 0 unless defined $message->{$key};
        return 0 if $message->{$key} ne $value;
    }
    return 1;
}

sub
route_trans {
    eval {
        my $message = shift or die 'message ref required';
        $config = {} unless $config;
        $config->{routes} = [] unless $config->{routes};
        my $continue_processing = 0;
        foreach my $route (@{$config->{routes}}) {
            die 'route requires match' unless $route->{match};
            die 'route match must be a HASH ref'
                if not ref $route->{match} or ref $route->{match} ne 'HASH';
            die 'route requires at least one forward' unless $route->{forwards};
            die 'route forward must be an ARRAY ref'
                if not ref $route->{forwards} or ref $route->{forwards} ne 'ARRAY';
            if(_match($message, $route->{match})) {
                foreach my $forward (@{$route->{forwards}}) {
                    die 'forward must have qname' unless $forward->{qname};
                    if(my $changes = $route->{changes}) {
                        die 'changes must be an ARRAY reference'
                            if not ref $changes or ref $changes ne 'ARRAY';
                        foreach my $change (@{$changes}) {
                            $change = Storable::dclone $change;
                            while(my ($key, $value) = each %$change) {
                                $message->{$key} = $value;
                            }
                        }
                    }
                    IPC::Transit::send(
                        qname => $forward->{qname},
                        message => $message
                    );
                    $continue_processing = 1 unless $route->{continue_processing};
                }
            }
            last if $continue_processing;
        }
    };
    die "IPC::Transit::Router::route_trans: $@\n" if $@;
    1;
}

1;

__END__

=head1 NAME

=head1 SYNOPSIS

IPC::Transit::Router - simple message routing and transformations

=head1 SYNOPSIS

 use strict;use warnings;
 use IPC::Transit::Router qw(config_trans route_trans);

 config_trans({
    routes => [
        {   match => {
                a => 'b',
            },
            forwards => [
                {   qname => 'test' },
            ]
            changes => [
                {   who => 'there' },
                {   123 => 234,
                    xray => 'kilo'
                }
            ]
        }
    ]
 });

 route_trans({a => 'b'});

 The follow message will appear on the local 'test' queue:
 {   a => 'b',
     who => 'there',
     123 => 234,
     xray => 'kilo',
 }

=head1 COPYRIGHT

Copyright (c) 2012, Dana M. Diederich. All Rights Reserved.

=head1 LICENSE

This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)

=head1 AUTHOR

Dana M. Diederich <diederich@gmail.com>

=cut
README

{   routes => [
        {   match => {
            },
            forwards => [
                {   qname => $q1,
                    hostname => $h1,
#                    continue => [0|1],
                }
            ],
            changes => [
                {   who => 'there' }
            ],
        },
    ]
}
