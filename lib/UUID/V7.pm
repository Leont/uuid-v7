package UUID::V7;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw/generate_uuid_v7/;

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

1;

# ABSTRACT: A precise UUIDv7 implementation

=head1 SYNOPSIS

 use UUID::V7 'generate_uuid_v7';

 my $uuid = generate_uuid_v7();

=head1 DESCRIPTION

=func generate_uuid_v7

This will generate a new UUIDv7 identifier. This will use 62 bits of timing information (±250 nanoseconds) for monotonicity with high-frequency UUID generation.
