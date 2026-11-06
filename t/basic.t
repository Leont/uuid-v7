#! perl

use strict;
use warnings;

use Test::More;

use Time::HiRes 'time';
use UUID::V7 ':all';

my @unsorted = map { generate_uuid_v7() } 0..999999;
my @sorted = sort @unsorted;

is(join('|', @sorted), join('|', @unsorted), 'UUIDs came in sorted order');

my $now = time;
my $uuid = generate_uuid_v7;
my $time = extract_uuid_v7_time($uuid);
ok($time - $now < 0.1, 'Times are equivalentish');

done_testing;
