use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More 'no_plan';

use IO::File;
use Geo::Gpx;
use_ok( 'Geo::Google::PolylineEncoder' );

# Test 1 - basic polyline with 3 points
# example from http://code.google.com/apis/maps/documentation/polylinealgorithm.html
{
    my @points = [
		  { lat => 38.5, lon => -120.2 },
		  { lat => 40.7, lon => -120.95 },
		  { lat => 43.252, lon => -126.453 },
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
    is( $eline->{levels}, 'PADAEA@CBP', 'ex2 levels' );
}

# Test 3
# A basic encoded polyline with ~100 points
{
    my $filename = 't/data/20061228.gpx';
    my $fh = IO::File->new( $filename );
    my $gpx = Geo::Gpx->new( input => $fh );

    my @track_points;
    my $iter = $gpx->iterate_trackpoints;
    while (my $pt = $iter->()) {
	push @track_points, $pt;
    }

    my $encoder = Geo::Google::PolylineEncoder->new(zoom_factor => 2, num_levels => 18);
    my $eline   = $encoder->encode( \@track_points );
    is( $eline->{num_levels}, 18, 'ex3 num_levels' );
    is( $eline->{zoom_factor}, 2, 'ex3 zoom_factor' );
    is( $eline->{points}, '{w}yHtP~MbEDzAECDf@HPh@N^ZTrAB`GA|DlF]pJ_BhBa@RI|AOvDyAhFkCPG`D_@hFU`@Ub@Kh@HVfCj@fE\zCI@PbAL`@f@|@d@^ZLj@HnDoAhGQRv@?LLrBpAvHbAjAdBlCrBfFTdFvA|SlA|J@^AST~@l@IxEcB`@WCAFST[b@Y`@EJj@SP_@LSv@?j@FnA@_@Hd@HV', 'ex3 points' );
    is( $eline->{levels}, 'PF@?C@@BD?GBA?ADA?CAB@BH??AB?AF@ADCFA?AD@BE@B?F@BCBA?@BAFB@BC?BB?P', 'ex3 levels' );
}


# Tests 4 & 5
# Borrowed from:
# http://facstaff.unca.edu/mcmcclur/GoogleMaps/EncodePolyline/examples.html
# We test for approximately equal as the encoding algorithms differ
SKIP: {
    eval 'use Test::Approx';
    skip 'Test::Approx not available', 8 if ($@);

    # load data for first two examples:
    my $filename = 't/data/MtMitchell.gpx';
    my $fh = IO::File->new( $filename );
    my $gpx = Geo::Gpx->new( input => $fh );

    my @track_points;
    my $iter = $gpx->iterate_trackpoints;
    while (my $pt = $iter->()) {
	push @track_points, $pt;
    }

    # Example 4
    # A basic encoded polyline with about 700 points
    {
	my $encoder = Geo::Google::PolylineEncoder->new(zoom_factor => 2, num_levels => 18);
	my $eline   = $encoder->encode( \@track_points );
	my $expect_points = '_gkxEv}|vNM]kB}B}@q@YKg@IqCGa@EcA?cAGg@Ga@q@q@aAg@UYGa@A]WYYw@cAUe@Oi@MgB?o@Do@\\yANoA?w@Ck@?kFBm@?_BDm@?gBBm@?s@Bo@BmGJ[Ao@?gTRsF?s@F}AIYg@Oo@IeAG]GyAMiDi@w@GkD?yAQs@AkB[MOkA_BYg@[aA}@kBwBaE{B}EYc@{@kBWg@eAk@i@e@k@?[Kc@c@Q]Us@Da@Na@lA]Fi@q@mA@g@Nm@I}@QoAi@{BUn@MbAWn@Yf@Qb@MvB@f@Id@Wn@}@dBU`@Wf@wAzBm@fA]HCc@XoC?s@Fe@f@aBJg@Tg@T[t@sBFs@Ga@Lc@~@oGLc@VmAf@aA\\QbA_@hCsA~@Y\\I~DcAZDb@PrC}@VMj@MXOh@Ir@[f@GFm@LW^]f@Yb@]x@i@uArHBpBmAl@Cd@E`@Vn@h@XbBNp@KhBeCnAaBNYzAoBnChJMd@?h@LX\\ZdC?d@H`@PdATjAF\\?`@YjBgA|AiAe@KMk@Hm@?k@Bc@\\Yr@y@zDaDK}AsB~B_AJwCzCk@BsAnB_AJ_F`DmDaFM_JsBeAfAgAGoCxJjIv@HjHoBn@e@p@wCxA^dAUfCeDjG}DYaAkIcJaFcC{@QuCdCcEJyI[iKwAUyE_J{KoDsFC{Cd@cApHkCyDuSkAaPbAeLnFkGrB{DdDsBL_A{@kC]}EsBp@yB@gIqA}FAw@c@E{CvAiEcEgLs@i@kDtAg@c@q@eQuCyJ{@k@mCCm@w@wCuNm@_@eIWoBiA}A{D]wC_BwE_AgS]{@kFuCcAB{@h@o@dA}AhIoDjDcCxAoAJ{JyCoDNoAa@cD{HiG_FaCBuElAq@kHZqPUwC_A_CiMlD{BFeC}@{@{@wA{DuFRyB]iCkDsBsAyBh@mEtC}BTcC_@uJiOe@aKk@cAsBgA{DWqB{@_DoDyFuLcHaDaBwBsEoPCwAlAaCr@e@lGwBn@cCQwC_EcNUqCTmC~CwKnAwBnBuAjSaFbFmHzFwD~CyEnH]tDqAnEkHhHwGD}Cm@cDyAcC}FaCcCuIoBmAyFv@mK~G_Cx@yJ`AsBe@yHyJwKcDmCcC]cAr@aEFyCbBaJq@mCaB_B{DF}Hw@aBxAi@lCiAtB_AL}HuCgG{@sBqA{CqF_@{Cf@cDvEqI|@oHgAaCwHmCe@_AVaISyCqDiI_GwEYyCvBgHCeFXaAvBqAdIg@hBaAlAwBn@oIq@sF{DyEkCu@qE[a@o@UyCn@sHQaAy@m@eAMuJhCwBA_CeEaEaA}OsJ_CwC_AeCGgAr@cFUyCyFsF_EeAsKhA{DEiTmEcBeBuE{M_H_L?cDlAkHY}CuAmEGyCfHqQ\\uTNcDv@mCr@q@hCg@hPdC`C?jNmE~Ld@xFs@zGsCtJkGnAkBOkC}AyAeDmAeLiBgKuJyBzB}@HiR_@sQsFgByAoAcHmAoBuWBkBy@b@ZoAoA}@eCe@gC]gK}BwF_L}HuGuH}LoJ}CeGkEgO_CsDkDoBiIaAgBmAsDwEiF{BgEuD{JcE]cA?kFg@_DaAgCoCyD}FuDqIoCuDsBwJ}AuFwDaBe@{DMsFhAw@Y{@kAg@oKsFeNgAeJkBsCuPeEaG_CkH_F{IiIeCe@wFCqA}AsAsGaByAcEQgYzG{@KqA}Bw@oI{BmMd@{@xA}AbFuClIiIfFmLrK{DzFwEbF{BfByAdHyJbBmGvAeBrBO~Db@xBc@`A}BtAeHhCgGz@mLlCoHjBkC|@u@rIqDxCeE`@_DUgCuFoIm@yCDuAvDsI`BaHbDqFdBqGv@_@|Fp@l@_@j@oA?uAkD_Nw@uF|DiV`BgB~BgAxHeBn@eAh@}CKkDuDcFWoAm@_KHkHhAsC`ByBrIeGvDiG~BaC~LsHJoAwIt@cHKu@d@kA`CcBdBgRnIyGbGwBt@{KEm@e@U{CdByNw@uEaBsAoFVkF{@{@T}DnDiKrDuJ`@{@e@a@{@]{Cc@w@eHyAoFgF{@WyMJkJ{@wD_AuH|@oHEsFgO_B{AcF}BgC\\oFfC{@Bs@a@sDoH_CgD_F}CaKY{KhEaGrDC_ApBsAtB_ETkCc@{@cE_DsDkHsDmEwE{BoDY{DoHTeAvBHxAxAm@f@y@E';
	my $expect_levels = 'P@B@D??@@?D?CA?B?CA?G@B@@B??@???A??@AA?B??AH@???@B@A@BAG?A?A@@??D@BAB@EACBBDC@AB@G@A??C@@D???A@BI@@@C?A?@C@B@B?AG?@@C?C@C???@?@D@B???GBCC?BGABE???FCAAEBB??B?G?@DBC@?D?@DGBBBBCBGDDDCGBFDBDBDCIBCFCCDBFDAHBDFCFEBCEBBIBDCBGCEECCEDFBCEEBECFBCBHCFACDBFCCBHDEBFCCBGBFBCDBEBEBDBGDBFBBECDCIBFBCCFBBEBHBDECCECFCEBJCDCGDBECGDCFCBBECGBECBCFCBHCECCFCCEBEDCGCBFCDBFCIDBCFBDBFBBFDCFBDBBEGDBDFCCJBDBBEE@CHBDBDDCFBECJBCDFBDEFCBFCCHBDBCFCCECCFCDBDCCFBBDBGCBCCBECBGCDCCHBEBEBECCGDECKBCGBBDECBBECBFBCFBBCCFACCGBDDBGBCBFCDAGBBEFBCDBFCBDBGBDCBDCJBEBBDCECHCDDCGCEBCDGBCBDDBFCBDBFCFEBBFBACGEBHCBCFBCBECECECDBP';
	is( $eline->{num_levels}, 18, 'ex4 num_levels' );
	is( $eline->{zoom_factor}, 2, 'ex4 zoom_factor' );
	is_approx( $eline->{points}, $expect_points, 'ex4 points', '25%' );
	is_approx( $eline->{levels}, $expect_levels, 'ex4 levels', '1%' );
    }

    # Example 5
    # The same polyline but using the parameters visible_threshold=0.00008, num_levels=9, and zoom_factor=4
    # viewable_distance_threshold
    # visible_threshold
    {
	my $encoder = Geo::Google::PolylineEncoder->new(zoom_factor => 4, num_levels => 9, visible_threshold => 0.00008);
	my $eline   = $encoder->encode( \@track_points );
	my $expect_points = '_gkxEv}|vNyB{CwA}@kKg@sAsBcB_@w@q@}AsCMwCr@yEl@gdA_MaBqJ[yBk@aPm[oBqAgAKu@aAOuANa@lA]Fi@q@mAFsC{@kEgBnFUdEiGbL]H\\mGtCaI?uAlAsHlAsDjH_D|EmA~@VvJwCTeAdD_CuArHBpBmAl@IfAVn@lCh@p@KdHqJnChJ?hB\\ZdC?lCp@hBFjFkDe@KMk@L}BlGuFK}AsB~B_AJwCzCk@BsAnB_AJ_F`DmDaFM_JsBeAfAgAGoCxJjIv@HjHoBn@e@p@wCxA^dAUfCeDjG}DYaAkIcJaFcC{@QuCdCcEJyI[iKwAUyEoOoSC{Cd@cApHkCyDuSkAaPbAeLnFkGrB{DdDsBL_A{@kC]}EsBp@yB@gIqA}FAw@c@E{CvAiEcEgLs@i@kDtAg@c@q@eQuCyJ{@k@mCCm@w@wCuNm@_@eIWoBiA}A{D]wC_BwE_AgS]{@kFuCcABkBnB}AhIoDjDcCxAoAJ{JyCoDNoAa@cD{HiG_FaCBuElAq@kHZqPUwC_A_CiMlD{BFeC}@{@{@wA{DuFRyB]iCkDsBsAyBh@mEtC}BTcC_@uJiOe@aKk@cAsBgA{DWqB{@_DoDyFuLcHaDaBwBsEoPCwAlAaCr@e@lGwBn@cCQwC_EcNUqCTmC~CwKnAwBnBuAjSaFbFmHzFwD~CyEnH]tDqAnEkHhHwGD}Cm@cDyAcC}FaCcCuIoBmAyFv@mK~G_Cx@yJ`AsBe@yHyJwKcDmCcC]cAr@aEFyCbBaJq@mCaB_B{DF}Hw@aBxAi@lCiAtB_AL}HuCgG{@sBqA{CqF_@{Cf@cDvEqI|@oHgAaCwHmCe@_AVaISyCqDiI_GwEYyCvBgHCeFXaAvBqAdIg@hBaAlAwBn@oIq@sF{DyEkCu@qE[a@o@UyCn@sHQaAy@m@eAMuJhCwBA_CeEaEaA}OsJ_CwC_AeCGgAr@cFUyCyFsF_EeAsKhA{DEiTmEcBeBuE{M_H_L?cDlAkHY}CuAmEGyCfHqQl@yYv@mCr@q@hCg@hPdC`C?jNmE~Ld@xFs@zGsCtJkGnAkBOkC}AyAeDmAeLiBgKuJyBzB}@HiR_@sQsFgByAoAcHmAoBuWBkBy@b@ZoAoA}@eCe@gC]gK}BwF_L}HuGuH}LoJ}CeGkEgO_CsDkDoBiIaAgBmAsDwEiF{BgEuD{JcE]cA?kFg@_DaAgCoCyD}FuDqIoCuDsBwJ}AuFwDaBe@{DMsFhAw@Y{@kAg@oKsFeNgAeJkBsCuPeEaG_CkH_F{IiIeCe@wFCqA}AsAsGaByAcEQgYzG{@KqA}Bw@oI{BmMd@{@xA}AbFuClIiIfFmLrK{DzFwEbF{BfByAdHyJbBmGvAeBrBO~Db@xBc@`A}BtAeHhCgGz@mLlCoHhDaErIqDxCeE`@_DUgCuFoIm@yCDuAvDsI`BaHbDqFdBqGv@_@|Fp@xAoB?uAkD_Nw@uF|DiV`BgB~BgAxHeBn@eAh@}CKkDuDcFWoAm@_KHkHhAsC`ByBrIeGvDiG~BaC~LsHJoAwIt@cHKu@d@kA`CcBdBgRnIyGbGwBt@{KEm@e@U{CdByNw@uEaBsAoFVkF{@{@T}DnDiKrDuJ`@{@e@a@{@]{Cc@w@eHyAoFgF{@WyMJkJ{@wD_AuH|@oHEsFgO_B{AcF}BgC\\oFfC{@Bs@a@sHwM_F}CaKY{KhEaGrDC_ApBsAtB_ETkCc@{@cE_DsDkHsDmEwE{BoDY{DoHTeAvBHxAxAm@f@y@E';
	my $expect_levels = 'G?@@???A??B??A@??@???@??A?@?B????A???@?A????A?@A?@???A@??@@A??????A@@@?A?A@?@?@?B??A??@?A@B?@A?A@??@??B?@??A?@@??@@A??@@?@?A???B?A?@?A???B@@?A???A?A??@?@?@?@?A@?A??@?@?B?A???A??@?B?@@??@?A?@?C?@?A@?@?A@?A???@?A?@???A??B?@??A??@?@@?A??A?@?A?B@??A?@?A??A@?A?@??@A@?@A??C?@??@@?B?@?@@?A?@?C??@A?@@A??A??B?@??A??@??A?@?@??A??@?A?????@??A?@??B?@?@?@??A@@?C??A??@@???@??A??A????A??A?@@?A???A?@A??@A??@?A??@?A?@??@?C?@??@?@?B?@@?A?@??@A???@@?A??@?A?A@??A??A@?B???A???@?@?@?@?G';
	is( $eline->{num_levels}, 9, 'ex5 num_levels' );
	is( $eline->{zoom_factor}, 4, 'ex5 zoom_factor' );
	is_approx( $eline->{points}, $expect_points, 'ex5 points', '25%' );
	is_approx( $eline->{levels}, $expect_levels, 'ex5 levels', '1%' );
    }
}



__END__
