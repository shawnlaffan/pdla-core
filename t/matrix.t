use strict;
use warnings;

use PDLA::LiteF;
use Test::More tests => 2;

use PDLA::Matrix;
my $m = mpdl([[1,2,1],[2,0,3],[1,1,1]]); # matrix with determinant 1

my $tol = $^O =~ /win32/i ? 1e-6 : 1e-15;
note "determinant: ",$m->det;
ok approx($m->det, 1, $tol);
ok approx($m->determinant, 1, 1e-15);

