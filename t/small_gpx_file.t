use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More;

BEGIN {
    eval "use Geo::Gpx";
    plan skip_all => 'Geo::Gpx not available' if $@;

    eval "use Test::Approx";
    plan skip_all => 'Test::Approx not available' if $@;

    plan 'no_plan';
}

use IO::File;

use_ok( 'Geo::Google::PolylineEncoder' );

# Test 3
# A basic encoded polyline with ~100 points

my $filename = 't/data/20061228.gpx';
my $fh = IO::File->new( $filename );
my $gpx = Geo::Gpx->new( input => $fh );

my @points;
my $iter = $gpx->iterate_trackpoints;
while (my $pt = $iter->()) {
    push @points, {lat => $pt->{lat}, lon => $pt->{lon}};
}

{
    my $encoder = Geo::Google::PolylineEncoder->new(zoom_factor => 2, num_levels => 18);
    my $eline   = $encoder->encode( \@points );
    is( $eline->{num_levels}, 18, 'ex3 num_levels' );
    is( $eline->{zoom_factor}, 2, 'ex3 zoom_factor' );
    is( $eline->{points}, '{w}yHtP~MbEDzAECDf@HPh@N^ZTrAB`GA|DlF]pJ_BhBa@RI|AOvDyAhFkCPG`D_@hFU`@Ub@Kh@HVfCj@fE\zCI@PbAL`@f@|@d@^ZLj@HnDoAhGQRv@?LLrBpAvHbAjAdBlCrBfFTdFvA|SlA|J@^AST~@l@IxEcB`@WCAFST[b@Y`@EJj@SP_@LSv@?j@FnA@_@Hd@HV', 'ex3 points' );
    is( $eline->{levels}, 'PF@?C@@BD?GBA?ADA?CAB@BH??AB?AF@ADCFA?AD@BE@B?FBBCBA?@BAFB@BC?BB?P', 'ex3 levels' );

    my $d_points = $encoder->decode_points( $eline->{points} );
    my $d_levels = $encoder->decode_levels( $eline->{levels} );
    is( scalar @$d_points, scalar @$d_levels, 'decode: num levels == num points' );
}

{
    my $encoder = Geo::Google::PolylineEncoder->new(zoom_factor => 2, num_levels => 18, visible_threshold => 0.00000001 );
    my $eline   = $encoder->encode( \@points );
    my $d_points = $encoder->decode_points( $eline->{points} );
    my $d_levels = $encoder->decode_levels( $eline->{levels} );
    is( scalar @$d_points, scalar @$d_levels, 'decode all: num levels == num points' );
    is( scalar @$d_points, scalar @points, 'decode all: num points == orig num' );

    # compare the decoded & original points, should be only rounding diffs
    for my $i (0 .. $#points) {
	my ($Pa, $Pb) = ($points[$i], $d_points->[$i]);
	is_approx_num( $Pa->{lon}, $Pb->{lon}, "d.lon[$i] =~ o.lon[$i]", 1e-5 );
	is_approx_num( $Pa->{lat}, $Pb->{lat}, "d.lat[$i] =~ o.lat[$i]", 1e-5 );
    }
}

