use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More 'no_plan';

use_ok( 'Geo::Google::PolylineEncoder' );

# RT #49327
# Result of encode_signed_number wrong for small negative numbers
{
    my $test_number = -0.000001;
    my $r = Geo::Google::PolylineEncoder->encode_signed_number($test_number);
    is( $r, chr(63), 'encode_signed_number( -0.000001 ) - RT 49327' );
}

# test the basic encoding functions
{
    my $enc = Geo::Google::PolylineEncoder->new;
    # example from http://code.google.com/apis/maps/documentation/polylinealgorithm.html
    is( $enc->encode_number( 17 ), 'P', 'encode_number: 17' );
    is( $enc->encode_number( 174 ), 'mD', 'encode_number: 174' );
    is( $enc->encode_signed_number( -179.9832104 ), '`~oia@', 'encode_signed_number: -179.9832104' );

    # this example was being encoded differently by both:
    # 'krchI' - http://code.google.com/apis/maps/documentation/polylineutility.html
    # 'irchI' - http://facstaff.unca.edu/mcmcclur/GoogleMaps/EncodePolyline/encodeForm.html
    # double-checked the polyline algorithm docs, seems they changed from using
    # floor() to using round(), so going with the first.
    is( $enc->encode_signed_number( 53.926935 ), 'krchI', 'encode_signed_number: 53.926935' );

    # trying to show that this number was encoded wrong, but it's right... ?
    # yet it appears wrong in Test 2 below?
    #      got: krchIwzo}@EqKa...
    # expected: krchIwzo}@CqKa...
    # why?
    is( $enc->encode_signed_number( 53.92696 ), 'orchI', 'encode_signed_number: 53.92696' );
}

# Test 1 - basic polyline with 3 points
# example from http://code.google.com/apis/maps/documentation/polylinealgorithm.html
{
    my $points = [
		  { lat => 38.5, lon => -120.2 }, # lvl 17
		  { lat => 40.7, lon => -120.95 }, # lvl 16
		  { lat => 43.252, lon => -126.453 }, # lvl 17
		 ];
    my $encoder = Geo::Google::PolylineEncoder->new(zoom_factor => 2, num_levels => 18);
    my $eline   = $encoder->encode( $points );
    is( $eline->{num_levels}, 18, 'ex1 num_levels' );
    is( $eline->{zoom_factor}, 2, 'ex1 zoom_factor' );
    is( $eline->{points}, '_p~iF~ps|U_ulLnnqC_mqNvxq`@', 'ex1 points' );
    is( $eline->{levels}, 'POP', 'ex1 levels' );

    my $d_points = $encoder->decode_points( $eline->{points} );
    my $d_levels = $encoder->decode_levels( $eline->{levels} );
    is( scalar @$d_points, scalar @$d_levels, 'decode: num levels == num points' );
    is_deeply( $d_points, $points, 'decode_points' );
    is_deeply( $d_levels, [ 17, 16, 17 ], 'decode_levels' );
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

# Test 2 - polyline with 12 points that kept on encoding incorrectly because I
# set escape_encoded_line => 1 by default.  This naturally screws things up...
# Also check that visible_threshold has desired effect
{
    my $points = [
		  { lat => 53.926935, lon => 10.244442 },
		  { lat => 53.926960, lon => 10.246454 },
		  { lat => 53.927131, lon => 10.248521 },
		  { lat => 53.927462, lon => 10.250555 },
		  { lat => 53.928056, lon => 10.253243 },
		  { lat => 53.928511, lon => 10.255110 }, # skipped @ default visible_threshold
		  { lat => 53.929217, lon => 10.257998 },
		  { lat => 53.930089, lon => 10.261353 },
		  { lat => 53.930831, lon => 10.263948 },
		  { lat => 53.931672, lon => 10.266299 }, # skipped @ default visible_threshold
		  { lat => 53.932730, lon => 10.269256 },
		  { lat => 53.933209, lon => 10.271115 },
		 ];

    my $encoder = Geo::Google::PolylineEncoder->new(zoom_factor => 2, num_levels => 18);
    my $eline   = $encoder->encode( $points );
    is( $eline->{num_levels}, 18, 'ex2 num_levels' );
    is( $eline->{zoom_factor}, 2, 'ex2 zoom_factor' );
    #is( $eline->{points}, 'irchIwzo}@EqKa@}KaAuKuByOgFu\\mD_TuCeO{Je`@}AsJ', 'ex2 points' );
    is( $eline->{points}, 'krchIwzo}@CqKa@}KaAwKwBwOgFw\\mD}SsCgO{Je`@_BsJ', 'ex2 points' ); # from google
    is( $eline->{levels}, 'PADAEA@CBP', 'ex2 levels' );

    $eline = $encoder->visible_threshold( 0.00000001 )->encode( $points );
    is( $eline->{points}, 'krchIwzo}@CqKa@}KaAwKwBwOyAuJmCaQmD}SsCgOgDuMsEoQ_BsJ', 'ex2 points' ); # from google
    is( $eline->{levels}, 'PKMKOEKJMBLP', 'ex2 levels' );
}

__END__
