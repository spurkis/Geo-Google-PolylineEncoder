use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More 'no_plan';

use IO::File;
use Geo::Gpx;
use_ok( 'Geo::Google::PolylineEncoder' );

# RT #49327
# Result of encode_signed_number wrong for small negative numbers
{
    my $test_number = -0.000001;
    my $r = Geo::Google::PolylineEncoder->encode_signed_number($test_number);
    is( $r, chr(63), 'encode_signed_number( -0.000001 ) - RT 49327' );
}

# test the basic encoding functions
# example from http://code.google.com/apis/maps/documentation/polylinealgorithm.html
{
    my $enc = Geo::Google::PolylineEncoder->new;
    is( $enc->encode_number( 17 ), 'P', 'encode_number: 17' );
    is( $enc->encode_number( 174 ), 'mD', 'encode_number: 174' );
    is( $enc->encode_signed_number( -179.9832104 ), '`~oia@', 'encode_signed_number: -179.9832104' );
}

# Test 1 - basic polyline with 3 points
# example from http://code.google.com/apis/maps/documentation/polylinealgorithm.html
{
    my @points = [
		  { lat => 38.5, lon => -120.2 }, # lvl 17
		  { lat => 40.7, lon => -120.95 }, # lvl 16
		  { lat => 43.252, lon => -126.453 }, # lvl 17
		 ];
    my $encoder = Geo::Google::PolylineEncoder->new(zoom_factor => 2, num_levels => 18);
    my $eline   = $encoder->encode( @points );
    is( $eline->{num_levels}, 18, 'ex1 num_levels' );
    is( $eline->{zoom_factor}, 2, 'ex1 zoom_factor' );
    is( $eline->{points}, '_p~iF~ps|U_ulLnnqC_mqNvxq`@', 'ex1 points' );
    is( $eline->{levels}, 'POP', 'ex1 levels' );
}

# Test 1a - polyline with only 2 points
# (resulting encodings were breaking Google Maps)
{
    my @points = [
		  { lat => 38.5, lon => -120.2 },
		  { lat => 40.7, lon => -120.95 },
		 ];
    my $encoder = Geo::Google::PolylineEncoder->new(zoom_factor => 2, num_levels => 18);
    my $eline   = $encoder->encode( @points );
    is( $eline->{num_levels}, 18, 'ex1a num_levels' );
    is( $eline->{zoom_factor}, 2, 'ex1a zoom_factor' );
    is( $eline->{points}, '_p~iF~ps|U_ulLnnqC', 'ex1a points' );
    is( $eline->{levels}, 'PP', 'ex1 levels' );
}

# Test 2 - polyline with 10 points that kept on encoding incorrectly because I
# set escape_encoded_line => 1 by default.  This naturally screws things up...
# To illustrate, I've included decoded (D) points from:
#  http://facstaff.unca.edu/mcmcclur/GoogleMaps/EncodePolyline/decode.html
# and points actually seen on the polyline (G)
{
    my $points = [
		  { lat => 53.926935, lon => 10.244442 },
		  #D: 53.92694, 10.24444
		  #G: 53.92694, 10.24444
		  { lat => 53.92696, lon => 10.246454 },
		  #D: 53.926970000000004, 10.246450000000001
		  #G: 53.926970000000004, 10.246450000000001
		  { lat => 53.927131, lon => 10.248521 },
		  #D: 53.92714, 10.248510000000001
		  #G: 53.92714, 10.248510000000001
		  { lat => 53.927462, lon => 10.250555 },
		  #D: 53.92747000000001, 10.25054
		  #G: 53.92747000000001, 10.25054
		  { lat => 53.928056, lon => 10.253243 },
		  #D: 53.92806, 10.25323
		  #G: 53.92806, 10.25323
		  { lat => 53.928511, lon => 10.25511 },
		  { lat => 53.929217, lon => 10.257998 },
		  #D: 53.92922000000001, 10.257990000000001
		  #G: 53.92922000000001, 10.257990000000001
		  { lat => 53.930089, lon => 10.261353 },
		  # ****** THINGS START DIFFERING HERE *******
		  #D: 53.93009000000001, 10.26134
		  #G: 53.92907, 10.25886
		  { lat => 53.930831, lon => 10.263948 },
		  #D: 53.93083000000001, 10.26393
		  #G: 53.93242000000001, 10.2596
		  { lat => 53.931672, lon => 10.266299 },
		  { lat => 53.93273, lon => 10.269256 },
		  #D: 53.93273000000001, 10.269240000000002
		  #G: 53.935010000000005, 10.261500000000002
		  { lat => 53.933209, lon => 10.271115 },
		  #D: 53.93321, 10.2711
		  #G: 53.94032000000001, 10.261980000000001
		  #G: 53.94218000000001, 10.261970000000002
		 ];

    my $encoder = Geo::Google::PolylineEncoder->new(zoom_factor => 2, num_levels => 18);
    my $eline   = $encoder->encode( $points );
    is( $eline->{num_levels}, 18, 'ex2 num_levels' );
    is( $eline->{zoom_factor}, 2, 'ex2 zoom_factor' );
    is( $eline->{points}, 'krchIwzo}@EqKa@}KaAuKuByOgFw\\mD}SsCeO{Je`@_BsJ', 'ex2 points' );
                          'krchIwzo}@CqKa@}KaAwKwBwOyAuJmCaQmD}SsCgOgDuMsEoQ_BsJ';
                          'krchIwzo}@CqKa@}KaAwKwBwOyAuJmCaQmD}SsCgOgDuMsEoQ_BsJ';
    is( $eline->{levels}, 'PADAEA@CBP', 'ex2 levels' );
}


__END__
