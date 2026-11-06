package UUID::V7;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw/generate_uuid_v7 extract_uuid_v7_time/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use Carp;
use Crypt::SysRandom 'random_bytes';
use POSIX::RT::Clock;

my $clock = POSIX::RT::Clock->new('realtime');
my $nano_to_milli = 1_000_000;
my $format = 'H8H4H4H4H12';
my $to_12_bit = 245; # $nano_to_mill / 245 == 4081
my $uuid_v7_marker = 0x7000;

sub generate_uuid_v7 {
	use integer;
	my $time = $clock->get_time;
	my $nanoseconds = $time->nsec;
	my $milliseconds = $time->sec * 1000 + $nanoseconds / $nano_to_milli;
	my $sub_milliseconds = $nanoseconds % $nano_to_milli / $to_12_bit;

	my $high = ($milliseconds << 16) + $sub_milliseconds | $uuid_v7_marker;
	my $result = pack 'Q>A8', $high, random_bytes(8);
	vec($result, 35, 2) = 2; # RFC 9562 variant

	return join '-', unpack $format, $result;
}

sub extract_uuid_v7_time {
	my ($uuid) = @_;
	my $binary = pack $format, split /-/, $uuid;
	croak 'UUID is not version 7' if vec($binary, 13, 4) != 7;

	my $first = unpack 'Q>', $binary;
	my $time = $first >> 16;
	$time += ($first & 0x0FFF) * $to_12_bit / $nano_to_milli;
	return $time / 1000;
}

1;

# ABSTRACT: A precise UUIDv7 implementation

=head1 SYNOPSIS

 use UUID::V7 ':all';

 my $uuid = generate_uuid_v7();
 my $time = extract_uuid_v7_time($uuid);

=head1 DESCRIPTION

=func generate_uuid_v7

This will generate a new UUIDv7 identifier. This will use 62 bits of timing information (±250 nanoseconds) for monotonicity with high-frequency UUID generation.

=func extract_uuid_v7_time

This will extract the time out of a UUIDv7.
