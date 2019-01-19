# This test checks that multiline comments in user code does not cause
# compilation errors. Strictly speaking, this is not really an Inline test,
# but Inline happens to provide the simplest framework for performing these
# tests. :-)
#  -- DCM, April 16, 2012

use strict;
use warnings;
use Test::More;
use PDL::LiteF;

# First some Inline administivia.
BEGIN {
   # Check for BSD platforms
   plan skip_all => 'Known problem: sf.net bug #3518190, t/inline-comment-test.t fails for BSD'
      if $^O =~ /(bsd|dragonfly)$/i;

   # Test for Inline and set options
   my $inline_test_dir = './.inline-ct';
   mkdir $inline_test_dir unless -d $inline_test_dir;
   
   # See if Inline loads without trouble, or bail out
   eval {
      require Inline;
      Inline->import (Config => DIRECTORY => $inline_test_dir , FORCE_BUILD => 1);
      1;
   } or do {
      plan skip_all => "Skipped: Inline not installed";
   };
   
   # Make sure we have a recent enough version of Inline
   eval q{
      use Inline 0.43;
      1;
   } or do {
      plan skip_all => 'Unable to load a new enough version of Inline';
   };

   # All clear, so declare the three tests
   plan tests => 3;
}

SKIP: {
# use Inline 'INFO'; # use to generate lots of info
eval { Inline->bind(Pdlpp => <<'EOF') };
# simple PP definition with user irritation tests :-)

pp_def('testinc',
	Pars => 'a(); [o] b()',
	Code => q{
	   /* emulate user debugging */
	   
	   /* Why doesn't this work???!!!! */
       threadloop %{
    /*         printf("  %f, %f\r", $a(), $b());
             printf("  Here\n");
	*/
    
	         /* Sanity check */
	         $b() = $a() + 1;
   
         %}
	   
	},
);

# make sure that if the word "threadloop" appears, later automatic threadloops
# will not be generated, even if the original threadloop was commented-out

pp_def('testinc2',
	Pars => 'a(); [o] b()',
	Code => q{
	   /* emulate user debugging */
	   
	   /* Why doesn't this work???!!!! */
   /*    threadloop %{
             printf("  %f, %f\r", $a(), $b());
             printf("  Here\n");
         %}
	*/
          /* Sanity check */
          $b() = $a() + 1;
	   
	},
);
EOF
is $@, '', 'compiled' or skip 'bind failed', 2;

my $x = sequence(3,3);

my $y = $x->testinc;

ok(all ($y == $x+1), 'Sanity check runs correctly');

# Test the inability to comment-out a threadloop. This is documented on the
# 11th page of the PDL::PP chapter of the PDL book. If somebody ever fixes this
# wart, this test will fail, in which case the book's text should be updated.
$y = $x->testinc2;
TODO: {
	# Note: This test appears to fail on Cygwin and some flavors of Linux.
	local $TODO = 'This test inexplicably passes on some machines';
	ok(not (all $y == $x + 1), 'WART: commenting out a threadloop does not work')
		or diag("\$x is $x and \$y is $y");
}
}
