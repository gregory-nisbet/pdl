# -*-perl-*-
#
# test some PDL core routines
#

use strict;
use Test::More;

BEGIN {
    # if we've got this far in the tests then
    # we can probably assume PDL::LiteF works!
    #
    eval {
        require PDL::LiteF;
    } or BAIL_OUT("PDL::LiteF failed: $@");
    plan tests => 75;
    PDL::LiteF->import;
}
$| = 1;

sub tapprox ($$) {
    my ( $x, $y ) = @_;
    my $d = abs( $x - $y );
    print "diff = [$d]\n";
    return $d <= 0.0001;
}

my $a_long = sequence long, 10;
my $a_dbl  = sequence 10;

my $b_long = $a_long->slice('5');
my $b_dbl  = $a_dbl->slice('5');

my $c_long = $a_long->slice('4:7');
my $c_dbl  = $a_dbl->slice('4:7');

# test 'sclr' method
#
is $b_long->sclr, 5, "sclr test of 1-elem pdl (long)";
is $c_long->sclr, 4, "sclr test of 3-elem pdl (long)";

ok tapprox( $b_dbl->sclr, 5 ), "sclr test of 1-elem pdl (dbl)";
ok tapprox( $c_dbl->sclr, 4 ), "sclr test of 3-elem pdl (dbl)";

# switch multielement check on
is( PDL->sclr({Check=>'barf'}), 2, "changed error mode of sclr" );

eval '$c_long->sclr';
like $@, qr/multielement piddle in 'sclr' call/, "sclr failed on multi-element piddle (long)";

eval '$c_dbl->sclr';
like $@, qr/multielement piddle in 'sclr' call/, "sclr failed on multi-element piddle (dbl)";

# test reshape barfing with negative args
#
eval 'my $d_long = $a_long->reshape(0,-3);';
like $@, qr/invalid dim size/, "reshape() failed with negative args (long)";

eval 'my $d_dbl = $a_dbl->reshape(0,-3);';
like $@, qr/invalid dim size/, "reshape() failed with negative args (dbl)";

# test reshape with no args
my ( $x, $y, $c );

$x = ones 3,1,4;
$y = $x->reshape;
ok eq_array( [ $y->dims ], [3,4] ), "reshape()";

# test reshape(-1) and squeeze
$x = ones 3,1,4;
$y = $x->reshape(-1);
$c = $x->squeeze;
ok eq_array( [ $y->dims ], [3,4] ), "reshape(-1)";
ok all( $y == $c ), "squeeze";

$c++; # check dataflow in reshaped PDL
ok all( $y == $c ), "dataflow"; # should flow back to b
ok all( $x == 2 ), "dataflow";

our $d = pdl(5); # zero dim piddle and reshape/squeeze
ok $d->reshape(-1)->ndims==0, "reshape(-1) on 0-dim PDL gives 0-dim PDL";
ok $d->reshape(1)->ndims==1, "reshape(1) on 0-dim PDL gives 1-dim PDL";
ok $d->reshape(1)->reshape(-1)->ndims==0, "reshape(-1) on 1-dim, 1-element PDL gives 0-dim PDL";

# reshape test related to bug SF#398 "$pdl->hdr items are lost after $pdl->reshape"
$c = ones(25);
$c->hdr->{demo} = "yes";
is($c->hdr->{demo}, "yes", "hdr before reshape");
$c->reshape(5,5);
is($c->hdr->{demo}, "yes", "hdr after reshape");



# test topdl

isa_ok( PDL->topdl(1),       "PDL", "topdl(1) returns a piddle" );
isa_ok( PDL->topdl([1,2,3]), "PDL", "topdl([1,2,3]) returns a piddle" );
isa_ok( PDL->topdl(1,2,3),   "PDL", "topdl(1,2,3) returns a piddle" );
$x=PDL->topdl(1,2,3);
ok (($x->nelem == 3  and  all($x == pdl(1,2,3))), "topdl(1,2,3) returns a 3-piddle containing (1,2,3)");


# test $PDL::undefval support in pdl (bug #886263)
#
is $PDL::undefval, 0, "default value of $PDL::undefval is 0";

$x = [ [ 2, undef ], [3, 4 ] ];
$y = pdl( $x );
$c = pdl( [ 2, 0, 3, 4 ] )->reshape(2,2);
ok all( $y == $c ), "undef converted to 0 (dbl)";
ok eq_array( $x, [[2,undef],[3,4]] ), "pdl() has not changed input array";

$y = pdl( long, $x );
$c = pdl( long, [ 2, 0, 3, 4 ] )->reshape(2,2);
ok all( $y == $c ), "undef converted to 0 (long)";

do {
    local($PDL::undefval) = -999;
    $x = [ [ 2, undef ], [3, 4 ] ];
    $y = pdl( $x );
    $c = pdl( [ 2, -999, 3, 4 ] )->reshape(2,2);
    ok all( $y == $c ), "undef converted to -999 (dbl)";

    $y = pdl( long, $x );
    $c = pdl( long, [ 2, -999, 3, 4 ] )->reshape(2,2);
    ok all( $y == $c ), "undef converted to -999 (long)";
} while(0);

##############
# Funky constructor cases

# pdl of a pdl
$x = pdl(pdl(5));
ok all( $x== pdl(5)), "pdl() can piddlify a piddle";

TODO: {
   local $TODO = 'Known_problems bug sf.net #3011879' if ($PDL::Config{SKIP_KNOWN_PROBLEMS} or exists $ENV{SKIP_KNOWN_PROBLEMS});

   # pdl of mixed-dim pdls: pad within a dimension
   $x = pdl( zeroes(5), ones(3) );
   ok all($x == pdl([0,0,0,0,0],[1,1,1,0,0])),"Piddlifying two piddles concatenates them and pads to length" or diag("a=$x\n");
}

# pdl of mixed-dim pdls: pad a whole dimension
$x = pdl( [[9,9],[8,8]], xvals(3)+1 );
ok all($x == pdl([[[9,9],[8,8],[0,0]] , [[1,0],[2,0],[3,0]] ])),"can concatenate mixed-dim piddles" or diag("a=$x\n");

# pdl of mixed-dim pdls: a hairier case
$c = pdl [1], pdl[2,3,4], pdl[5];
ok all($c == pdl([[[1,0,0],[0,0,0]],[[2,3,4],[5,0,0]]])),"Can concatenate mixed-dim piddles: hairy case" or diag("c=$c\n");

# same thing, with undefval set differently
do {
    local($PDL::undefval) = 99;
    $c = pdl [1], pdl[2,3,4], pdl[5];
    ok all($c == pdl([[[1,99,99],[99,99,99]],[[2,3,4],[5,99,99]]])), "undefval works for padding" or diag("c=$c\n");;
} while(0);

# empty pdl cases
eval {$x = zeroes(2,0,1);};
ok(!$@,"zeroes accepts empty PDL specification");

eval { $y = pdl($x,sequence(2,0,1)); };
ok((!$@ and all(pdl($y->dims) == pdl(2,0,1,2))), "concatenating two empties gives an empty");

eval { $y = pdl($x,sequence(2,1,1)); };
ok((!$@ and all(pdl($y->dims) == pdl(2,1,1,2))), "concatenating an empty and a nonempty treats the empty as a filler");

eval { $y = pdl($x,5) };
ok((!$@ and all(pdl($y->dims)==pdl(2,1,1,2))), "concatenating an empty and a scalar on the right works");
ok( all($y==pdl([[[0,0]]],[[[5,0]]])), "concatenating an empty and a scalar on the right gives the right answer");

eval { $y = pdl(5,$x) };
ok((!$@ and all(pdl($y->dims)==pdl(2,1,1,2))), "concatenating an empty and a scalar on the left works");
ok( all($y==pdl([[[5,0]]],[[[0,0]]])), "concatenating an empty and a scalar on the left gives the right answer");

# end

# cat problems
eval {cat(1, pdl(1,2,3), {}, 6)};
ok ($@ ne '', 'cat barfs on non-piddle arguments');
like ($@, qr/Arguments 0, 2 and 3 are not piddles/, 'cat correctly identifies non-piddle arguments');
$@ = '';
eval {cat(1, pdl(1,2,3))};
like($@, qr/Argument 0 is not a piddle/, 'cat uses good grammar when discussing non-piddles');
$@ = '';

my $two_dim_array = cat(pdl(1,2), pdl(1,2));
eval {cat(pdl(1,2,3,4,5), $two_dim_array, pdl(1,2,3,4,5), pdl(1,2,3))};
ok ($@ ne '', 'cat barfs on mismatched piddles');
like($@, qr/The dimensions of arguments 1 and 3 do not match/
	, 'cat identifies all piddles with differing dimensions');
like ($@, qr/\(argument 0\)/, 'cat identifies the first actual piddle in the arg list');
$@ = '';
eval {cat(pdl(1,2,3), pdl(1,2))};
like($@, qr/The dimensions of argument 1 do not match/
	, 'cat uses good grammar when discussing piddle dimension mismatches');
$@ = '';
eval {cat(1, pdl(1,2,3), $two_dim_array, 4, {}, pdl(4,5,6), pdl(7))};
ok ($@ ne '', 'cat barfs combined screw-ups');
like($@, qr/Arguments 0, 3 and 4 are not piddles/
	, 'cat properly identifies non-piddles in combined screw-ups');
like($@, qr/arguments 2 and 6 do not match/
	, 'cat properly identifies piddles with mismatched dimensions in combined screw-ups');
like($@, qr/\(argument 1\)/,
	'cat properly identifies the first actual piddle in combined screw-ups');
$@ = '';

eval {$x = cat(pdl(1),pdl(2,3));};
ok(!$@, 'cat(pdl(1),pdl(2,3)) succeeds');
ok( ($x->ndims==2 and $x->dim(0)==2 and $x->dim(1)==2), 'weird cat case has the right shape');
ok( all( $x == pdl([1,1],[2,3]) ), "cat does the right thing with catting a 0-pdl and 2-pdl together");
$@='';

my $by=xvals(byte,5)+253;
my $so=xvals(short,5)+32766;
my $lo=xvals(long,5)+32766;
my $fl=float(xvals(5)+0.2);
my @list = ($lo,$so,$fl,$by);
my $c2 = cat(@list);
is($c2->type,'float','concatentating different datatypes returns the highest type');
my $i=0;
map{ ok(all($_==$list[$i]),"cat/dog symmetry for values ($i)"); $i++; }$c2->dog;

# new_or_inplace
$x = sequence(byte,5);


$y = $x->new_or_inplace;
ok( all($y==$x) && ($y->get_datatype ==  $x->get_datatype), "new_or_inplace with no pref returns something like the orig.");

$y++;
ok(all($y!=$x),"new_or_inplace with no inplace flag returns something disconnected from the orig.");

$y = $x->new_or_inplace("float,long");
ok($y->type eq 'float',"new_or_inplace returns the first type in case of no match");

$y = $x->inplace->new_or_inplace;
$y++;
ok(all($y==$x),"new_or_inplace returns the original thing if inplace is set");
ok(!($y->is_inplace),"new_or_inplace clears the inplace flag");

# check reshape and dims.  While we're at it, check null & empty creation too.
my $null = null;
my $empty = zeroes(0);
ok($empty->nelem==0,"you can make an empty PDL with zeroes(0)");
ok("$empty" =~ m/Empty/, "an empty PDL prints 'Empty'");

ok($null->info =~ /^PDL->null$/, "null piddle's info is 'PDL->null'");
my $mt_info = $empty->info;
$mt_info =~m/\[([\d,]+)\]/;
my $mt_info_dims = pdl("$1");
ok(any($mt_info_dims==0), "empty piddle's info contains a 0 dimension");
ok($null->isnull && $null->isempty, "a null piddle is both null and empty");
ok(!$empty->isnull && $empty->isempty, "an empty piddle is empty but not null");

$x = short pdl(3,4,5,6);
eval { $x->reshape(2,2);};
ok(!$@,"reshape succeeded in the normal case");
ok( ( $x->ndims==2 and $x->dim(0)==2 and $x->dim(1)==2 ), "reshape did the right thing");
ok(all($x == short pdl([[3,4],[5,6]])), "reshape moved the elements to the right place");

$y = $x->slice(":,:");
eval { $y->reshape(4); };
ok( $@ !~ m/Can\'t/, "reshape doesn't fail on a PDL with a parent" );

