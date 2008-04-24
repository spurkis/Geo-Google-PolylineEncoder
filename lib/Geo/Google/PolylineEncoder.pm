=head1 NAME

Geo::Google::PolylineEncoder - encode lat/lngs to Google Maps Polylines

=head1 SYNOPSIS

  use Geo::Google::PolylineEncoder;

  my $points = [
		{ lat => 38.5, lon => -120.2 },
	        { lat => 40.7, lon => -120.95 },
	        { lat => 43.252, lon => -126.453 },
	       ];
  my $encoder = Geo::Google::PolylineEncoder->new;
  my $eline   = $encoder->encode( $points );
  print $eline->{num_levels};  # 18
  print $eline->{zoom_factor}; # 2
  print $eline->{points};      # _p~iF~ps|U_ulLnnqC_mqNvxq`@
  print $eline->{levels};      # POP

  # in Javascript, assuming eline was encoded as JSON:
  # ... load GMap2 ...
  var opts = {
    points: eline.points,
    levels: eline.levels,
    numLevels: eline.num_levels,
    zoomFactor: eline.zoom_factor,
  };
  var line = GPolyline.fromEncoded( opts );

=cut

package Geo::Google::PolylineEncoder;

use strict;
use warnings;

use accessors qw(num_levels zoom_factor visible_threshold force_endpoints
		 zoom_level_breaks escape_encoded_points);
use constant defaults => {
			  num_levels  => 18,
			  zoom_factor => 2,
			  force_endpoints => 1,
			  escape_encoded_points => 0,
			  visible_threshold => 0.00001,
			 };
our $VERSION = 0.02;

# The constructor
sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->init(@_);
    return $self;
}

sub init {
    my ($self, %args) = @_;

    foreach my $attr (keys %{ $self->defaults }) {
	$self->$attr($self->defaults->{$attr});
    }

    foreach my $attr (keys %args) {
	$self->$attr($args{$attr});
    }

    my @zoom_level_breaks;
    for my $i (1 .. $self->num_levels) {
	push @zoom_level_breaks,
	  $self->visible_threshold * $self->zoom_factor ** ($self->num_levels - $i);
    }

    $self->zoom_level_breaks(\@zoom_level_breaks);
}

# The main function.  Essentially the Douglas-Peucker
# algorithm, adapted for encoding. Rather than simply
# eliminating points, we record their distance from the
# segment which occurs at that recursive step.  These
# distances are then easily converted to zoom levels.
sub encode {
    my ($self, $points) = @_;

    my @stack;
    my @dists;
    my $abs_max_dist = 0;

    if(@$points > 2) {
	push @stack, [0, @$points - 1];
	while(@stack > 0) {
	    my $current = pop @stack;

	    # create a line segment between p1 & p2 and calculate its length
	    my $p1 = $points->[$current->[0]];
	    my $p2 = $points->[$current->[1]];
	    # cache the square of the seg length for use in calcs later...
	    my $seg_length_squared = (($p2->{lat} - $p1->{lat}) ** 2 +
				      ($p2->{lon} - $p1->{lon}) ** 2);
	    my $seg_length = sqrt($seg_length_squared);

	    my $max_dist = 0;
	    my $max_dist_idx;
	    for (my $i = $current->[0] + 1; $i < $current->[1]; $i++) {
		my $dist = $self->distance($points->[$i], $p1, $p2, $seg_length, $seg_length_squared);
		# See if this distance is the greatest for this segment so far:
		if ($dist > $max_dist) {
		    $max_dist = $dist;
		    $max_dist_idx = $i;
		    if ($max_dist > $abs_max_dist) {
			$abs_max_dist = $max_dist;
		    }
		}
	    }

	    # If the point that had the greatest distance from the line seg is
	    # also greater than our threshold, process again using it as a new
	    # start/end point for the line.
	    if ($max_dist > $self->visible_threshold) {
		# store this distance - we'll use it later when creating zoom values
		$dists[$max_dist_idx] = $max_dist;
		push @stack, [$current->[0], $max_dist_idx];
		push @stack, [$max_dist_idx, $current->[1]];
	    }
	}
    } else {
	# Do nothing with only 2 points
    }

    my $eline = {
		 points => $self->encode_points($points, \@dists),
		 levels => $self->encode_levels($points, \@dists, $abs_max_dist),
		 num_levels => $self->num_levels,
		 zoom_factor => $self->zoom_factor,
		};

    if ($self->escape_encoded_points) {
	# create string literals:
	$eline->{points} =~ s/\\/\\\\/g;
    }

    return $eline;
}


# distance(p0, p1, p2) computes the distance between the point p0 and the line
# segment [p1, p2].  Maths borrowed from GMapPolylineEncoder.rb by Joel Rosenberg
# bit more numerically stable.
sub distance {
    my ($self, $p, $a, $b, $seg_length, $seg_length_squared) = @_;

    my $dist;
    my ($Py, $Px, $Ay, $Ax, $By, $Bx) =
      ($p->{lat}, $p->{lon}, $a->{lat}, $a->{lon}, $b->{lat}, $b->{lon});

    # Approximate distance using flat (Euclidian) geometry, rather than
    # trying to bring the curvature of the earth into it.  This greatly
    # simplifies things...
    #if ($Ay == $By && $Ax == $Bx) {
    if ($seg_length == 0) {
	# The line is really just a point, so calc dist between it and $p:
	$dist = sqrt(($By - $Py) ** 2 + ($Bx - $Px) ** 2);
    } else {
	# Thanks to Philip Nicoletti's explanation:
	#   http://www.codeguru.com/forum/printthread.php?t=194400
	#
	# So, to find out how far the line segment (AB) is from the point (P),
	# let 'I' be the point of perpendicular projection of P on AB.  The
	# parameter 'r' indicates I's position along AB, and is computed by
	# the dot product of AP and AB divided by the square of the length
	# of AB:
	#
	#       AP . AB      (Px-Ax)(Bx-Ax) + (Py-Ay)(By-Ay)
        #   r = --------  =  -------------------------------
	#       ||AB||^2                   L^2
	#
	# r can be interpreded ala:
	#
        #   r=0      I = A
        #   r=1      I = B
        #   r<0      I is on the backward extension of A-B
        #   r>1      I is on the forward extension of A-B
        #   0<r<1    I is interior to A-B
	#
	# In cases 1-4 we can simply use the distance between P and either A or B.
	# In case 5 we can use the distance between I and P.  To do that we need to
	# find I:
	#
	#   Ix = Ax + r(Bx-Ax)
	#   Iy = Ay + r(By-Ay)
	#
	# And the distance from A to I = r*L.
	# Use another parameter s to indicate the location along IP, with the 
	# following meaning:
        #    s<0      P is left of AB
	#    s>0      P is right of AB
	#    s=0      P is on AB
	#
	# Compute s as follows:
	#
	#       (Ay-Py)(Bx-Ax) - (Ax-Px)(By-Ay)
        #   s = -------------------------------
        #                     L^2
	#
	# Then the distance from P to I = |s|*L.

	my $r = (($Px - $Ax) * ($Bx - $Ax) +
		 ($Py - $Ay) * ($By - $Ay)) / $seg_length_squared;
	if ($r >= 0.0 || $r <= 1.0) {
	    # The perpendicular point intersects the line
	    my $s = (($Ay - $Py) * ($Bx - $Ax) -
		     ($Ax - $Px)*($By - $Ay)) / $seg_length_squared;
	    $dist = abs($s) * $seg_length;
	} else {
	    # The point is closest to an endpoint. Find out which one:
	    my $dist1 = ($Px - $Ax)**2 + ($Py - $Ay)**2;
	    my $dist2 = ($Px - $Bx)**2 + ($Py - $By)**2;
	    # avoid doing sqrts:
	    $dist = ($dist1 < $dist2) ? sqrt($dist1) : sqrt($dist2);
	}
    }

    return $dist;
}

# The encode_points function is very similar to Google's
# http://www.google.com/apis/maps/documentation/polyline.js
# The key difference is that not all points are encoded,
# since some were eliminated by Douglas-Peucker.
sub encode_points {
    my ($self, $points, $dists) = @_;

    my $encoded_points = "";
    my $oldencoded_points = "";
    my ($last_lat, $last_lon) = (0.0, 0.0);

    for (my $i = 0; $i < @$points; $i++) {
	if (defined($dists->[$i]) || $i == 0 || $i == @$points - 1) {
	    my $point = $points->[$i];
	    my $lat = $point->{lat};
	    my $lon = $point->{lon};

	    # compute deltas
	    my $delta_lat = $lat - $last_lat;
	    my $delta_lon = $lon - $last_lon;
	    ($last_lat, $last_lon) = ($lat, $lon);

	    $encoded_points .=
	      $self->encode_signed_number($delta_lat) .
	      $self->encode_signed_number($delta_lon);
	}
    }

    return $encoded_points;
}


# Use compute_level to march down the list of points and encode the levels.
# Like encode_points, we ignore points whose distance (in dists) is undefined.
# See http://code.google.com/apis/maps/documentation/polylinealgorithm.html
sub encode_levels {
    my ($self, $points, $dists, $abs_max_dist) = @_;

    my $i;
    my $encoded_levels = "";
    if ($self->force_endpoints) {
	$encoded_levels .= $self->encode_number($self->num_levels - 1);
    } else {
	$encoded_levels .= $self->encode_number($self->num_levels - $self->compute_level($abs_max_dist) - 1);
    }

    for ($i=1; $i < @$points - 1; $i++) {
	if (defined $dists->[$i]) {
	    $encoded_levels .= $self->encode_number($self->num_levels - $self->compute_level($dists->[$i]) - 1);
	}
    }

    if ($self->force_endpoints) {
	$encoded_levels .= $self->encode_number($self->num_levels - 1);
    } else {
	$encoded_levels .= $self->encode_number($self->num_levels - $self->compute_level($abs_max_dist) - 1);
    }

    return $encoded_levels;
}


# This computes the appropriate zoom level of a point in terms of it's 
# distance from the relevant segment in the DP algorithm.  Could be done
# in terms of a logarithm, but this approach makes it a bit easier to
# ensure that the level is not too large.
sub compute_level {
    my ($self, $dd) = @_;

    my $lev;
    if($dd > $self->visible_threshold) {
	$lev = 0;
	while ($dd < $self->zoom_level_breaks->[$lev]) {
	    $lev++;
	}
	return $lev;
    }
}

# Based on the official google example
sub encode_signed_number {
    my ($self, $orig_num) = @_;

    # Take the decimal value and multiply it by 1e5, flooring the result:

    # Note 1: we limit the number to 5 decimal places with sprintf to avoid
    # perl's rounding errors (they can throw the line off by a big margin sometimes)
    # From Geo::Google: use the correct floating point precision or else
    # 34.06694 - 34.06698 will give you -3.999999999999999057E-5 which doesn't
    # encode properly. -4E-5 encodes properly.

    # Note 2: we use sprintf(%8.0f ...) rather than int() for similar reasons
    # (see perldoc -f int), though there's not much in it and the sprintf approach
    # ends up doing more of a round() than a floor() in some cases:
    #   floor = -30   num=-30 *int=-29  1e5=-30  %3.5f=-0.00030  orig=-0.000300000000009959
    #   floor = 119  *num=120  int=119  1e5=120  %3.5f=0.00120   orig=0.0011999999999972
    # We don't use floor() to avoid a dependency on POSIX

    # do this in a series of steps so we can see what's going on in the debugger:
    my $num3_5 = sprintf('%3.5f', $orig_num)+0;
    my $num_1e5 = $num3_5 * 1e5;
    my $num = sprintf('%8.0f', $num_1e5)+0;

    # my $int = int($num_1e5);
    # my $floor = floor($num_1e5);
    # warn "floor = $floor\tnum=$num\tint=$int\t1e5=$num_1e5\t%3.5f=$num3_5\torig=$orig_num\n"
    #   if ($floor != $num or $num != $int);


    # Convert the decimal value to binary.
    # Note that a negative value must be inverted and provide padded values toward the byte boundary
    # (perl ints are already manipulatable in binary, so do nothing)

    # Shift the binary value:
    $num = $num << 1;

    # If the original decimal value was negative, invert this encoding:
    if ($orig_num < 0) {
	$num = ~$num;
    }

    return $self->encode_number($num);
}

# Based on the official google example
sub encode_number {
    my ($self, $num) = @_;

    my $encodeString = "";
    my ($nextValue, $finalValue);

    # Break the binary value out into 5-bit chunks (starting from the right hand side):
    while ($num >= 0x20) {
	$nextValue = (0x20 | ($num & 0x1f)) + 63;
	$encodeString .= chr($nextValue);
	$num >>= 5;
    }
    $finalValue = $num + 63;
    $encodeString .= chr($finalValue);

    return $encodeString;
}


1;

__END__

=head1 DESCRIPTION

This module encodes a list of lat/lon points representing a polyline into a
format for use with Google Maps.  This format is described here:

L<http://code.google.com/apis/maps/documentation/polylinealgorithm.html>

The module is a port of Mark McClure's C<PolylineEncoder.js> with some minor
tweaks.  The original can be found here:

L<http://facstaff.unca.edu/mcmcclur/GoogleMaps/EncodePolyline/>

=head1 CONSTRUCTOR & ACCESSORS

=over 4

=item new( [%args] )

Create a new encoder.  Arguments are optional and correspond to the accessor
with the same name: L</num_levels>, L</zoom_factor>, L</visible_threshold>,
L</force_endpoints>.

Note: there's nothing stopping you from setting these properties each time you
L</encode> a polyline.

=item num_levels

How many different levels of magnification the polyline has.
Default: 18.

=item zoom_factor

The change in magnification between those levels (see L</num_levels>).
Default: 2.

=item visible_threshold

Indicates the length of a barely visible object at the highest zoom level.
Default: 0.00001.

=item force_endpoints

Indicates whether or not the endpoints should be visible at all zoom levels.
force_endpoints is.  Probably should stay true regardless.
Default: 1=true.

=item escape_encoded_points

Indicates whether or not the encoded points should have escape characters
escaped, eg:

  $points =~ s/\\/\\\\/g;

This is useful if you'll be evalling the resulting strings, or copying them into
a static document.

B<Warning:> don't turn this on if you'll be passing the encoded points straight
on to your application, or you'll get unexpected results (ie: lines that start
out right, but end up horribly wrong).  It may even crash your browser.

Default: 0=false.

=back

=head1 METHODS

=over 4

=item encode( \@points );

Encode the points into a string for use with Google Maps C<GPolyline.fromEncoded>
using a variant of the Douglas-Peucker algorithm and the Polyline encoding
algorithm defined by Google.

Expects a reference to a C<@points> array ala:

  [
   { lat => 38.5, lon => -120.2 },
   { lat => 40.7, lon => -120.95 },
   { lat => 43.252, lon => -126.453 },
  ];

Returns a hashref containing:

  {
   points => 'encoded points string',
   levels => 'encoded levels string',
   num_levels => int($num_levels),
   zoom_factor => int($zoom_factor),
  };

You can then use the L<JSON> modules (or XML, or whatever) to pass the encoded
values to your Javascript application for use there.

=back

=head1 TODO

Benchmarking, & maybe bring distance calcs in-line as Joel Rosenberg did:
L<http://facstaff.unca.edu/mcmcclur/GoogleMaps/EncodePolyline/gmap_polyline_encoder.rb.txt>

=head1 AUTHOR

Steve Purkis <spurkis@cpan.org>

Ported from Mark McClure's C<PolylineEncoder.js> which can be found here:
L<http://facstaff.unca.edu/mcmcclur/GoogleMaps/EncodePolyline/PolylineEncoder.html>

Some encoding ideas borrowed from L<Geo::Google>.

=head1 COPYRIGHT

Copyright (c) 2008 Steve Purkis.
Released under the same terms as Perl itself.

=head1 SEE ALSO

L<http://code.google.com/apis/maps/documentation/polylinealgorithm.html>,
L<http://facstaff.unca.edu/mcmcclur/GoogleMaps/EncodePolyline/PolylineEncoder.html>
(JavaScript implementation),
L<http://www.usnaviguide.com/google-encode.htm> (similar implementation in perl),
L<Geo::Google>,
L<JSON>

=cut
