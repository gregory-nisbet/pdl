
# Test routine for PDL::IO::Misc module

use strict; 

use PDL::LiteF;
use PDL::IO::Misc;

use File::Temp qw( tempfile tempdir );

kill 'INT',$$  if $ENV{UNDER_DEBUGGER}; # Useful for debugging.

use Test::More tests => 23;

sub tapprox {
        my($x,$y) = @_;
        my $c = abs($x-$y);
        my $d = max($c);
        $d < 0.0001;
}

my $tempd = tempdir( CLEANUP => 1 ) or die "Couldn't get tempdir\n";
my ($fileh,$file) = tempfile( DIR => $tempd );

############# Test rcols with colsep and missing fields ###################

print $fileh <<EOD;
1,6,11
2,7,
3,8,13
4,,14
5,10,15
EOD
close($fileh);

my $x = do {
   local $PDL::undefval = -1;
   rcols $file, [], { colsep=>',' };
};

is( (sum($x<0)==2 && $x->getdim(0)==5 && $x->getdim(1)==3), 1, "rcols with undefval and missing cols" );
unlink $file || warn "Could not unlink $file: $!";

############# Test rcols with filename and pattern #############

($fileh,$file) = tempfile( DIR => $tempd );
print $fileh <<EOD;
1 2
2 33 FOO
3 7
4 9  FOO
5 66
EOD
close($fileh);

my $y;
($x,$y) = rcols $file,0,1;
$x = long($x); $y=long($y);

is( (sum($x)==15 && max($y)==66 && $y->getdim(0)==5), 1, "rcols with filename" );

($x,$y) = rcols $file, "/FOO/",0,1;
$x = long($x);
$y=long($y);

is( (sum($x)==6 && max($y)==33 && $y->getdim(0)==2), 1, "rcols with filename + pattern" );

############# Test rcols with file handle with nothing left #############

open my $fh, '<', $file;
# Pull in everything:
my @slurp = <$fh>;
# Now apply rcols:
$@ = '';
$x = eval { rcols $fh };
is($@, '', 'rcols does not die on a used file handle');
close $fh;

############### Test rgrep with FILEHANDLE #####################

($fileh,$file) = tempfile( DIR => $tempd );
print $fileh <<EOD;
foo"1" -2-
foo"2"  Test -33-
foo"3" jvjtvbjktrbv -7-
foo"4" -9-
fjrhfiurhe foo"5" jjjj -66-
EOD
close($fileh);

open(OUT, $file) || die "Can not open $file for reading\n";
($x,$y) = rgrep {/foo"(.*)".*-(.*)-/} *OUT;
$x = long($x); $y=long($y);
close(OUT);

is( (sum($x)==15 && max($y)==66 && $y->getdim(0)==5), 1, "rgrep" );

########### Explicit test of byte swapping #################

$x = short(3); $y = long(3); # $c=long([3,3]);
bswap2($x); bswap4($y);
is(sum($x)==768 && sum($y)==50331648,1,"bswap2");

############# Test rasc  #############

($fileh,$file) = tempfile( DIR => $tempd );
print $fileh <<EOD;
0.231862613
0.20324005
0.067813045
0.040103501
0.438047631
0.283293628
0.375427346
0.195821617
0.189897617
0.035941205
0.339051483
0.096540854
0.25047197
0.579782013
0.236164184
0.221568561
0.009776015
0.290377604
0.785569601
0.260724391

EOD
close($fileh);

$x = PDL->null;
$x->rasc($file,20);
is( abs($x->sum - 5.13147) < .01, 1, "rasc on null piddle" );
 
$y = zeroes(float,20,2);
$y->rasc($file);
is( abs($y->sum - 5.13147) < .01, 1, "rasc on existing piddle" );

eval '$y->rasc("file_that_does_not_exist")';
like( $@, qr/Can't open/, "rasc on non-existant file" );

unlink $file || warn "Could not unlink $file: $!"; # clean up

#######################################################
# Tests of rcols() options
#   EXCLUDE/INCLUDE/LINES/DEFTYPE/TYPES

($fileh,$file) = tempfile( DIR => $tempd );
print $fileh <<EOD;
1 2
# comment line
3 4
-5 6
7 8
EOD
close($fileh);

($x,$y) = rcols $file,0,1;
is( $x->nelem==4 && sum($x)==6 && sum($y)==20, 1,
    "rcols: default" );

($x,$y) = rcols \*DATA,0,1;
is( $x->nelem==4 && sum($x)==6 && sum($y)==20, 1,
    "rcols: pipe" );

($x,$y) = rcols $file,0,1, { INCLUDE => '/^-/' };
is( $x->nelem==1 && $x->at(0)==-5 && $y->at(0)==6, 1,
    "rcols: include pattern" );

($x,$y) = rcols $file,0,1, { LINES => '-2:0' };
is( $x->nelem==3 && tapprox($x,pdl(-5,3,1)) && tapprox($y,pdl(6,4,2)), 1,
    "rcols: lines option" );

use PDL::Types;
($x,$y) = rcols $file, { DEFTYPE => long };
is( $x->nelem==4 && $x->get_datatype==$PDL_L && $y->get_datatype==$PDL_L, 1,
    "rcols: deftype option" );

($x,$y) = rcols $file, { TYPES => [ ushort ] };
is( $x->nelem==4 && $x->get_datatype==$PDL_US && $y->get_datatype==$PDL_D, 1,
    "rcols: types option" );

is( UNIVERSAL::isa($PDL::IO::Misc::deftype,"PDL::Type"), 1,
    "PDL::IO::Misc::deftype is a PDL::Type object" );
is( $PDL::IO::Misc::deftype->[0], double->[0],
    "PDL::IO::Misc::deftype check" );

$PDL::IO::Misc::deftype = short;
($x,$y) = rcols $file;
is( $x->get_datatype, short->[0], "rcols: can read in as 'short'" );

unlink $file || warn "Could not unlink $file: $!";

($fileh,$file) = tempfile( DIR => $tempd );
eval { wcols $x, $y, $fileh };
is(!$@,1, "wcols" );
unlink $file || warn "Could not unlink $file: $!";

($fileh,$file) = tempfile( DIR => $tempd );
eval { wcols $x, $y, $fileh, {FORMAT=>"%0.3d %0.3d"}};
is(!$@,1, "wcols FORMAT option");
unlink $file || warn "Could not unlink $file: $!";

($fileh,$file) = tempfile( DIR => $tempd );
eval { wcols "%d %d", $x, $y, $fileh;};
is(!$@,1, "wcols format_string");
unlink $file || warn "Could not unlink $file: $!";

($fileh,$file) = tempfile( DIR => $tempd );
eval { wcols "arg %d %d", $x, $y, $fileh, {FORMAT=>"option %d %d"};};
is(!$@,1, "wcols format_string override");

open($fileh,"<",$file) or warn "Can't open $file: $!";
readline(*$fileh); # dump first line
like(readline($fileh),qr/^arg/, "wcols format_string obeyed");
unlink $file || warn "Could not unlink $file: $!";

1;

__DATA__
1 2
# comment line
3 4
-5 6
7 8
