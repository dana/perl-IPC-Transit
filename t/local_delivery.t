#!env perl
use strict;use warnings;

use lib '../lib';
use lib 'lib';
use Test::More tests => 2;

use_ok('IPC::Transit') or exit;
use_ok('IPC::Transit::Test') or exit;


#clean out the queue if there's something in it
IPC::Transit::Test::clear_test_queue();
