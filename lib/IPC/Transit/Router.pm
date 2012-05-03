package IPC::Transit::Router;

use strict;use warnings;
use IPC::Transit;

use vars qw(
    $config
);
sub
config {
    $config = shift;
}

sub
route {

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
