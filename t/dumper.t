use strict;
use Test::More;
use Config;

sub inpath {
  my ($prog) = @_;
  for ( split $Config{path_sep}, $ENV{PATH} ) {
    return 1 if -x "$_/$prog$Config{exe_ext}"
  }
  return;
}

BEGIN {
   eval "use Convert::UU;";
   my $hasuuencode = !$@ || (inpath('uuencode') && inpath('uudecode'));

   if ($hasuuencode) {
      plan tests => 16;
   } else {
      plan skip_all => "Skip neither uuencode/decode nor Convert:UU is available\n";
   }

   use PDL;
}

########### First test the load...
use_ok('PDL::IO::Dumper');

########### Dump several items and make sure we get 'em back...
# a: trivial
# b: 0-d
# c: inline
# d: advanced expr

my ( $s, $x );

eval '$s = sdump({a=>3,b=>pdl(4),c=>xvals(3,3),d=>xvals(4,4)});';
ok(!$@, 'Call sdump()')
   or diag("Call sdump() output string:\n$s\n");
$x = eval $s;
ok(!$@, 'Can eval dumped data code') or diag("The output string was '$s'\n");
ok(ref $x eq 'HASH', 'HASH was restored');
ok(($x->{a}==3), 'SCALAR value restored ok');
ok(((ref $x->{b} eq 'PDL') && ($x->{b}==4)), '0-d PDL restored ok');
ok(((ref $x->{c} eq 'PDL') && ($x->{c}->nelem == 9) 
      && (sum(abs(($x->{c} - xvals(3,3))))<0.0000001)), '3x3 PDL restored ok');
ok(((ref $x->{d} eq 'PDL') && ($x->{d}->nelem == 16)
      && (sum(abs(($x->{d} - xvals(4,4))))<0.0000001)), '4x4 PDL restored ok');

########## Dump a uuencoded expr and try to get it back...
# e: uuencoded expr
eval '$s = sdump({e=>xvals(25,25)});';
ok(!$@, 'sdump() of 25x25 PDL to test uuencode dumps');

#diag $s,"\n";

$x = eval $s;
ok(!$@, 'Can eval dumped 25x25 PDL');

# $s and $@ can be long so try and make things a bit clearer in the
# output
#
if ( $@ ) {
   diag "--- ERROR ---\n";
   diag "--Error message start:\n";
   diag $@;
   diag "\n--Error message end:\n";
   diag "String was:\n$s\n";
   diag "--- ERROR (end) ---\n";
}

ok((ref $x eq 'HASH'), 'HASH structure for uuencoded 25x25 PDL restored');
ok(((ref $x->{e} eq 'PDL') 
      && ($x->{e}->nelem==625)
      && (sum(abs(($x->{e} - xvals(25,25))))<0.0000001)), 'Verify 25x25 PDL restored data');

########## Check header dumping...
my $y;
eval '$x = xvals(2,2); $x->sethdr({ok=>1}); $x->hdrcpy(1); $y = xvals(25,25); $y->sethdr({ok=>2}); $y->hdrcpy(0); $s = sdump([$x,$y,yvals(25,25)]);';
ok(!$@, 'Check header dumping');

$x = eval $s;
ok((!$@ && (ref $x eq 'ARRAY')), 'ARRAY can restore');

ok(eval('$x->[0]->hdrcpy() == 1 && $x->[1]->hdrcpy() == 0'), 'Check hdrcpy()\'s persist');
ok(eval('($x->[0]->gethdr()->{ok}==1) && ($x->[1]->gethdr()->{ok}==2)'), 'Check gethdr() values persist');

# end
