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
                          'krchIwzo}@CqKa@}KaAwKwBwOyAuJmCaQmD}SsCgOgDuMsEoQ_BsJ';
                          'krchIwzo}@CqKa@}KaAwKwBwOyAuJmCaQmD}SsCgOgDuMsEoQ_BsJ';
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
    is( $eline->{levels}, 'PF@?C@@BD?GBA?ADA?CAB@BH??AB?AF@ADCFA?AD@BE@B?FBBCBA?@BAFB@BC?BB?P', 'ex3 levels' );
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


# Test - RT #46337 Truncated levels & points?
# Wrong number of levels & fails to display the last few points
{
    my @points =
      [
       { lat => 37.7989715881429, lon => -122.474730627442 },
       { lat => 37.7991044932363, lon => -122.474760648468 },
       { lat => 37.7997304316188, lon => -122.474656120138 },
       { lat => 37.7999895395801, lon => -122.474652853546 },
       { lat => 37.7999212677559, lon => -122.474858626516 },
       { lat => 37.799943774049,  lon => -122.474999623484 },
       { lat => 37.800059487658,  lon => -122.475178420175 },
       { lat => 37.8004643339641, lon => -122.475519161545 },
       { lat => 37.8011545426717, lon => -122.475676860194 },
       { lat => 37.8016095214345, lon => -122.475636726377 },
       { lat => 37.8022878678636, lon => -122.475663162897 },
       { lat => 37.8025453271667, lon => -122.475633288859 },
       { lat => 37.8028771202341, lon => -122.47561651559 },
       { lat => 37.8028878805922, lon => -122.475808002577 },
       { lat => 37.8031295274047, lon => -122.47643430601 },
       { lat => 37.8031161231909, lon => -122.476967879765 },
       { lat => 37.8032644778961, lon => -122.477394945039 },
       { lat => 37.8037137067877, lon => -122.477241719044 },
       { lat => 37.8040357702484, lon => -122.477039498073 },
       { lat => 37.804074836754,  lon => -122.477030419892 },
       { lat => 37.8042903811412, lon => -122.476890165752 },
       { lat => 37.8043130717563, lon => -122.476846736984 },
       { lat => 37.8045306223459, lon => -122.476874043697 },
       { lat => 37.8047248947759, lon => -122.476814977033 },
       { lat => 37.8048390088063, lon => -122.476742060609 },
       { lat => 37.8049875167115, lon => -122.476683316412 },
       { lat => 37.805215742199,  lon => -122.476537473695 },
       { lat => 37.8053411001784, lon => -122.476421204776 },
       { lat => 37.8055118549266, lon => -122.476218070222 },
       { lat => 37.8056829885773, lon => -122.476101482588 },
       { lat => 37.8057514525547, lon => -122.476057729227 },
       { lat => 37.8059114063705, lon => -122.475998899088 },
       { lat => 37.8060597207586, lon => -122.475896887119 },
       { lat => 37.8061846917281, lon => -122.475694084825 },
       { lat => 37.8062987382832, lon => -122.47560673853 },
       { lat => 37.8064240952632, lon => -122.475490457589 },
       { lat => 37.8068497536903, lon => -122.475992265848 },
       { lat => 37.8069530668413, lon => -122.476063663163 },
       { lat => 37.8072028225147, lon => -122.475614758302 },
       { lat => 37.8074184448507, lon => -122.475209374188 },
       { lat => 37.807566300183,  lon => -122.475006390348 },
       { lat => 37.8076348328425, lon => -122.474977061759 },
       { lat => 37.8076922462421, lon => -122.475019925719 },
       { lat => 37.8078186367323, lon => -122.475134426842 },
       { lat => 37.8079338431969, lon => -122.475306691234 },
       { lat => 37.8080370899649, lon => -122.475363658691 },
       { lat => 37.8081513962978, lon => -122.4753339946 },
       { lat => 37.8082195376959, lon => -122.475218129872 },
       { lat => 37.8082881325219, lon => -122.475203216677 },
       { lat => 37.8083685604356, lon => -122.475274770449 },
       { lat => 37.8084830601043, lon => -122.475288375808 },
       { lat => 37.8085746649273, lon => -122.475302154912 },
       { lat => 37.8086436464467, lon => -122.47537378136 },
       { lat => 37.8086897446167, lon => -122.475445581523 },
       { lat => 37.808689937897,  lon => -122.475488848464 },
       { lat => 37.8087364224447, lon => -122.475647179773 },
       { lat => 37.8087487680079, lon => -122.47584902979 },
       { lat => 37.8087500553651, lon => -122.476137500553 },
       { lat => 37.8087969823783, lon => -122.476396793661 },
       { lat => 37.8088896251485, lon => -122.476641351198 },
       { lat => 37.808959235524,  lon => -122.476842375928 },
       { lat => 37.8094273436666, lon => -122.476939682306 },
       { lat => 37.8100228890407, lon => -122.477091685002 },
       { lat => 37.8104463544408, lon => -122.477058875889 },
       { lat => 37.8110915194506, lon => -122.477224017339 },
      ];

    my $encoder = Geo::Google::PolylineEncoder->new(zoom_factor => 2, num_levels => 18);
    my $eline   = $encoder->encode( @points );
    is( $eline->{num_levels}, 18, 'RT 46337 num_levels' );
    is( $eline->{zoom_factor}, 2, 'RT 46337 zoom_factor' );
    is( $eline->{points}, 'qrueFdzojVYB}BSq@?Jd@CZUb@qAbAiC`@yAGgCBs@CaAEAf@o@|B@fB]tAyA[sBeACIk@Be@KUK]Mm@[YWa@g@o@a@_@I[SYi@o@e@sAbBUJ{AkD]e@MEc@^W^SLWEKYMAONi@BMNGJIh@C`BGr@_@xA}APwB\\sAGaC`@', 'RT 46337 points' );
    is( $eline->{levels}, 'PA@D@CACD@@@FAAAFA@BB@@CA@A@@BAE@EA@F@@CA@C@@E@A@AE@AAP', 'RT 46337 levels' );
}



__END__
