use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More;

BEGIN {
    eval "use Geo::Gpx";
    plan skip_all => 'Geo::Gpx not available' if $@;
    plan 'no_plan';
}

use IO::File;

use_ok( 'Geo::Google::PolylineEncoder' );

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


