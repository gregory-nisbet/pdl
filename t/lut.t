# -*-perl-*-
use strict;
use warnings;
use Test::More tests => 8;

use PDL::LiteF;
use PDL::Types;
use PDL::Graphics::LUT;

my @names = lut_names();
ok( $#names > -1 , "lut_names returns non-empty list");

my @cols = lut_data( $names[0] );
is( $#cols, 3, "lut_data returns 4 columns");
is( $cols[0]->nelem, $cols[1]->nelem, "equal number of elements in cols 0 and 1");
is( $cols[2]->get_datatype, $PDL_F, "datatype of col 2 is float");

# check we can reverse things
my @cols2 = lut_data( $names[0], 1 );
ok( all approx($cols[3]->slice('-1:0'),$cols2[3]), "reverse lut works");

# check we know about the intensity ramps
my @ramps = lut_ramps();
ok( $#ramps > -1, "lut_ramps returns some ramps");

# load in a different intensity ramp
my @cols3 = lut_data( $names[0], 0, $ramps[0] ); 
is( $cols3[0]->nelem, $cols3[1]->nelem, "intensity ramp nelem check");
ok( all approx($cols[1],$cols3[1]), "intensity ramp vals check");

