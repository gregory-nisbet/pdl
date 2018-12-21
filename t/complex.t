use PDL::LiteF;
use PDL::Complex;
use PDL::Config;
use PDL::Math;

BEGIN {
   use Test::More tests => 131;
}

sub tapprox {
	my($x,$y) = @_;
	my $c = abs($x-$y);
	my $d = max($c);
	$d < 0.0001;
}

#Type of cplx and cmplx
$x=sequence(2);
$y=$x->cplx;
ok(ref $y eq 'PDL::Complex', 'type of cplx');
ok(ref $x eq 'PDL', "cplx doesn't modify original pdl");
$z=$y->real;
ok(ref $z eq 'PDL', 'real returns type to pdl');
ok(ref $y eq 'PDL::Complex', "real doesn't change type of parent");
#Should there be a real subroutine, such as complex, that does change
#the parent?
$y=$x->complex;
ok(ref $y eq 'PDL::Complex', 'type of complex');
ok(ref $x eq 'PDL::Complex', 'complex does modify original pdl');

#Check r2C
ok(ref r2C(1) eq 'PDL::Complex', 'type of r2C');
is(r2C(1)->re, 1, 'real part of r2C');
is(r2C(1)->im, 0, 'imaginary part of r2C');

#Check i2C
ok(ref i2C(1) eq 'PDL::Complex', 'type of i2C');
is(i2C(1)->re, 0, 'real part of i2C');
is(i2C(1)->im, 1, 'imaginary part of i2C');

#Test mixed complex-real operations

$ref = pdl(-1,1);
$x = i - 1;

ok(ref $x eq PDL::Complex, 'type promotion i - real scalar');
ok(tapprox($x->real,$ref), 'value from i - real scalar');

$x = 1-i;
ok(ref $x eq PDL::Complex, 'type promption real scalar - i');
ok(tapprox($x->real,-$ref), 'value from real scalar - i');

$ref = pdl([[-2,1],[-3,1]]);
$x = i - pdl(2,3);

ok(ref $x eq PDL::Complex, 'type promotion i - real piddle');
ok(tapprox($x->real,$ref), 'value from i - real piddle');

$x = pdl(2,3) - i;
ok(ref $x eq PDL::Complex, 'type promption real piddle - i');
ok(tapprox($x->real,-$ref), 'value from real piddle - i');

# dataflow from complex to real
$ar = $x->real;
$ar++;
ok(tapprox($x->real, -$ref+1), 'complex to real dataflow');

# dataflow from real to complex when using cplx

$refc=$ref->copy;
$ac = $refc->cplx;
$ac .= $ac-1-i;
ok(tapprox($refc, $ref-1), 'real to complex dataflow');

# no dataflow from real to complex when complex

$refc=$ref->copy;
$ac = $refc->complex;
$ac .= $ac-1-i;
ok(tapprox($refc->real, $ref-1), 'real to complex dataflow');

#Check Cr2p and Cp2r
ok(tapprox(Cr2p(pdl(1,1)), pdl(sqrt(2),atan2(1,1))), 'rectangular to polar');
ok(tapprox(Cp2r(pdl(sqrt(2),atan2(1,1))), pdl(1,1)), 'polar to rectangular');

# Check that converting from re/im to mag/ang and
#  back we get the same thing
$x = cplx($ref);
my $y = $x->Cr2p()->Cp2r();
ok(tapprox($x-$y, 0), 'check re/im and mag/ang equivalence');

# Test Cadd, Csub, Cmul, Cscale, Cdiv
$x=1+2*i;
$y=3+4*i;
$a=3;
$pa=pdl(3);
ok(ref Cadd($x,$y) eq 'PDL::Complex', 'Type of Cadd');
ok(tapprox(Cadd($x,$y)->real, $x->real+$y->real), 'Value of Cadd');
ok(ref Csub($x,$y) eq 'PDL::Complex', 'Type of Csub');
ok(tapprox(Csub($x,$y)->real, $x->real-$y->real), 'Value of Csub');
#ok(ref Cmul($x,$y) eq 'PDL::Complex', 'Type of Cmul');
#ok(tapprox(Cmul($x,$y)->real,
#	   pdl($x->re*$y->re-$x->im*$y->im,
#	       $x->re*$y->im+$x->im*$y->re)), 'Value of Cmul');
ok(ref Cscale($x,$a) eq 'PDL::Complex', 'Type of Cscale with scalar');
ok(tapprox(Cscale($x,$a)->real, $x->real*$a), 'Value of Cscale with scalar');
ok(ref Cscale($x,$pa) eq 'PDL::Complex', 'Type of Cscale with pdl');
ok(tapprox(Cscale($x,$pa)->real, $x->real*$pa), 'Value of Cscale with pdl');
#ok(ref Cdiv($x,$y) eq 'PDL::Complex', 'Type of Cdiv');
#ok(tapprox(Cdiv($x,$y)->real,
#	   Cscale(Cmul($x,$y->Cconj), 1/$y->Cabs2)->real), 'Value of Cdiv');
# to test Cabs, Cabs2, Carg (ref PDL)

$x = cplx($ref);
$cabs = sqrt($x->re**2+$x->im**2);

ok(ref Cabs $x eq 'PDL', 'Cabs type');
ok(ref Cabs2 $x eq 'PDL', 'Cabs2 type');
ok(ref Carg $x eq 'PDL', 'Carg type');
ok(tapprox($cabs, Cabs $x), 'Cabs value');
ok(tapprox($cabs**2, Cabs2 $x), 'Cabs2 value');
ok(tapprox(atan2($x->im, $x->re), Carg $x), 'Carg value');

#Csin, Ccos, Ctan

ok(ref Csin(i) eq 'PDL::Complex', 'Csin type');
ok(tapprox(Csin($x->re->r2C)->re, sin($x->re)), 'Csin of reals');
ok(tapprox(Csin(i*$x->im)->im, sinh($x->im)), 'Csin of imags');
ok(ref Ccos(i) eq 'PDL::Complex', 'Ccos type');
ok(tapprox(Ccos($x->re->r2C)->re, cos($x->re)), 'Ccos of reals');
ok(tapprox(Ccos(i*$x->im)->re, cosh($x->im)), 'Ccos of imags');
ok(ref Ctan(i) eq 'PDL::Complex', 'Ctan type');
ok(tapprox(Ctan($x->re->r2C)->re, tan($x->re)), 'Ctan of reals');
ok(tapprox(Ctan(i*$x->im)->im, tanh($x->im)), 'Ctan of imags');

#Cexp, Clog, Cpow
ok(ref Cexp(i) eq 'PDL::Complex', 'Cexp type');
ok(tapprox(Cexp($x->re->r2C)->re, exp($x->re)), 'Cexp of reals');
ok(tapprox(Cexp(i*$x->im->r2C)->real, pdl(cos($x->im), sin($x->im))->mv(1,0)),
	   'Cexp of imags ');
ok(ref Clog(i) eq 'PDL::Complex', 'Clog type');
ok(tapprox(Clog($x)->real,
	   pdl(log($x->Cabs), atan2($x->im, $x->re))->mv(1,0)),
   'Clog of reals');
ok(ref Cpow($x, r2C(2)) eq 'PDL::Complex', 'Cpow type');
ok(tapprox(Cpow($x,r2C(2))->real,
	   pdl($x->re**2-$x->im**2, 2*$x->re*$x->im)->mv(1,0)),
   'Cpow value');

#Csqrt
ok(ref Csqrt($x) eq 'PDL::Complex', 'Csqrt type');
ok(tapprox((Csqrt($x)*Csqrt($x))->real, $x->real), 'Csqrt value');
TODO: {
      local $TODO="Cpow doesn't understand a real argument";
      ok(tapprox(Cpow(i,2)->real, pdl(-1,0)), 'scalar power of i');
      ok(tapprox(Cpow(i,pdl(2))->real, pdl(1,0)), 'real pdl power of i');
}

#Casin, Cacos, Catan
ok(ref Casin($x) eq 'PDL::Complex', 'Casin type');
ok(tapprox(Csin(Casin($x))->real, $x->real), 'Casin value');
ok(ref Cacos($x) eq 'PDL::Complex', 'Cacos type');
ok(tapprox(Ccos(Cacos($x))->real, $x->real), 'Cacos value');
ok(ref Catan($x) eq 'PDL::Complex', 'Catan type');
ok(tapprox(Ctan(Catan($x))->real, $x->real), 'Catan value');

#Csinh, Ccosh, Ctanh
ok(ref Csinh($x) eq 'PDL::Complex', 'Csinh type');
ok(tapprox(Csinh($x)->real, (i*Csin($x/i))->real), 'Csinh value');
ok(ref Ccosh($x) eq 'PDL::Complex', 'Ccosh type');
ok(tapprox(Ccosh($x)->real, (Ccos($x/i))->real), 'Ccosh value');
ok(ref Ctanh($x) eq 'PDL::Complex', 'Ctanh type');
ok(tapprox(Ctanh($x)->real, (i*Ctan($x/i))->real), 'Ctanh value');

#Casinh, Cacosh, Catanh
ok(ref Casinh($x) eq 'PDL::Complex', 'Casinh type');
ok(tapprox(Csinh(Casinh($x))->real, $x->real), 'Casinh value');
ok(ref Cacosh($x) eq 'PDL::Complex', 'Cacosh type');
ok(tapprox(Ccosh(Cacosh($x))->real, $x->real), 'Cacosh value');
ok(ref Catanh($x) eq 'PDL::Complex', 'Catanh type');
ok(tapprox(Ctanh(Catanh($x))->real, $x->real), 'Catanh value');


# Croots

ok(ref Croots($x, 5) eq 'PDL::Complex', 'Croots type');
ok(tapprox(Cpow(Croots($x, 5), r2C(5))->real, $x->real->slice(':,*1')),
   'Croots value');
ok(tapprox(Croots($x, 5)->sumover, pdl(0)),
   'Croots center of mass');

#Check real and imaginary parts
is((2+3*i)->re, 2, 'Real part');
is((2+3*i)->im, 3, 'Imaginary part');

#rCpolynomial
 TODO: {
     local $TODO="rCpolynomial doesn't return a PDL::Complex";
     ok(ref rCpolynomial(pdl(1,2,3), $x) eq 'PDL::Complex',
	'rCpolynomial type');
}
ok(tapprox(rCpolynomial(pdl(1,2,3), $x),
	   (1+2*$x+3*$x**2)->real), 'rCpolynomial value');


# Check cat'ing of PDL::Complex
$y = $x->copy + 1;
my $bigArray = $x->cat($y);
ok(abs($bigArray->sumover->sumover +  8 - 4*i) < .0001, 'check cat for PDL::Complex');
ok(abs($bigArray->sum() +  8 - 4*i) < .0001, 'check cat for PDL::Complex');

my $z = pdl(0) + i*pdl(0);
$z **= 2;

ok($z->at(0) == 0 && $z->at(1) == 0, 'check that 0 +0i exponentiates correctly'); # Wasn't always so.

my $zz = $z ** 0;

#Are these results really correct? WLM

ok($zz->at(0) == 1 && $zz->at(1) == 0, 'check that 0+0i ** 0 is 1+0i');

$z **= $z;

ok($z->at(0) == 1 && $z->at(1) == 0, 'check that 0+0i ** 0+0i is 1+0i');

my $r = pdl(-10) + i*pdl(0);
$r **= 2;

ok($r->at(0) < 100.000000001 && $r->at(0) > 99.999999999 && $r->at(1) == 0,
  'check that imaginary part is exactly zero'); # Wasn't always so

#Check Csumover sumover, Cprodover and prodover
$x=sequence(2,3)+1;
$y=$x->copy->complex;
ok(ref $y->Csumover eq 'PDL::Complex', 'Type of Csumover');
is($y->Csumover->dim(0), 2, 'Dimension 0 of Csumover');
ok(tapprox($y->Csumover->real, $x->mv(1,0)->sumover),
   'Csumover value');
ok(ref $y->sumover eq 'PDL::Complex', 'Type of sumover');
is($y->sumover->dim(0), 2, 'Dimension 0 of sumover');
ok(tapprox($y->sumover->real, $x->mv(1,0)->sumover), 'sumover value');
ok(ref sumover($y) eq 'PDL::Complex', 'Type of sumover');
 TODO: {
     local $TODO="sumover as method and as function differ";
     is(sumover($y)->dim(0), 2, 'Dimension 0 of sumover');
   SKIP: {
       todo_skip "sumover as function is real sumover", 1;
       ok(tapprox(sumover($y)->real, $x->mv(1,0)->sumover), 'sumover
	  value');
     }
}

ok(ref $y->Cprodover eq 'PDL::Complex', 'Type of Cprodover');
is($y->Cprodover->dim(0), 2, 'Dimension 0 of Cprodover');
ok(tapprox($y->Cprodover->real,
	   ($y->slice(':,(0)')*$y->slice(':,(1)')*$y->slice(':,(2)'))->real),
	  'Value of Cprodover');
ok(ref $y->prodover eq 'PDL::Complex', 'Type of prodover');
     is($y->prodover->dim(0), 2, 'Dimension 0 of prodover');
ok(tapprox($y->prodover->real,
	   ($y->slice(':,(0)')*$y->slice(':,(1)')*$y->slice(':,(2)'))->real),
   'Value of prodover');


#Check sum
$x=sequence(2,3)+1;
$y=$x->copy->complex;
ok(ref	$y->sum eq 'PDL::Complex', 'Type of sum');
is($y->sum->dims, 1, 'Dimensions of sum');
is($y->sum->dim(0), 2, 'Dimension 0 of sum');
ok(tapprox($y->sum->real, $x->mv(1,0)->sumover), 'Value of sum');

#Check prod
$x=sequence(2,3)+1;
$y=$x->copy->complex;
ok(ref $y->prod eq 'PDL::Complex', 'Type of prod');
is($y->prod->dims, 1, 'Dimensions of prod');
is($y->prod->dim(0), 2, 'Dimension 0 of prod');
ok(tapprox($y->prod->real, $y->prodover->real),
   'Value of prod');


 TODO: {
     local $TODO = "Known_problems sf.net bug #1176614" if ($PDL::Config{SKIP_KNOWN_PROBLEMS} or exists $ENV{SKIP_KNOWN_PROBLEMS} );


   # Check stringification of complex piddle
   # This is sf.net bug #1176614
   my $c =  9.1234 + 4.1234*i;
   my $c211 = $c->dummy(2,1);
   my $c211str = "$c211";
   ok($c211str=~/(9.123|4.123)/, 'sf.net bug #1176614');
}

TODO: {
      local $TODO="Autoincrement creates new copy, so doesn't flow";
      # autoincrement flow
      $x=i;
      $y=$x;
      $y++;
      ok(tapprox($x->real, $y->real), 'autoincrement flow');
      diag("$x should have equaled $y");
}

TODO: {
      local $TODO="Computed assignment creates new copy, so doesn't flow";
      # autoincrement flow
      $x=i;
      $y=$x;
      $y+=1;
      ok(tapprox($x->real, $y->real), 'computed assignment flow');
      diag("$x should have equaled $y");
}
TODO: {
      local $TODO="Computed assignment doesn't modify slices";
      # autoincrement flow
      $x=sequence(2,3)->complex;
      $y=$x->copy;
      $x+=$x;
      $y->slice('')+=$y;
      ok(tapprox($x->real, $y->real), 'computed assignment to slice');
      diag("$x should have equaled $y");
}

$x=3+4*i;$y=4+2*i;$c=1+1*i;
is(Ccmp(Cmul($x,$y),4+22*i),0,"Cmul");
is(Ccmp($x*$y,4+22*i),0,"overloaded *");
is(Ccmp(Cdiv($x,$y),1 + 0.5*i),0,"Cdiv");
is(Ccmp($x/$y,1+0.5*i),0,"overloaded /");
ok(tapprox(Cabs(atan2(pdl(1)->r2C,pdl(0)->r2C)),PDL::Math::asin(1)),"atan2");

TODO: {
      local $TODO="Transpose of complex data should leave 0-th dimension alone";
      $x=sequence(2,3,4)->complex;
      $y=$x->transpose;
      is($y->dim(0),2, "Keep dimension 0 when transposing");
}
TODO: {
      local $TODO="complex numbers should not be so after moving dimension 0";

      $x=sequence(2,2)->complex;
      $y=$x->mv(0,1);
      ok(ref $y eq 'PDL', 'PDL::Complex becomes real PDL after moving dim 0');
}

#test overloaded nonsensical comparison operators
{
    my $less = 3-4*i;
    my $equal = -1*(-3+4*i);
    my $more = 3+2*i;
    is($less<$more,1,'less than');
    is(($less<=$equal) && ($equal<$more),1,'less than or equal to');
    is($less==$equal,1,'equal to');
    is($less!=$equal,0,'not equal to');
    is($more>$equal,1,'greater than');
    is($more>=$equal,1,'greater than or equal to');
}
