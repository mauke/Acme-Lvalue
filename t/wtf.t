use warnings;
use strict;

use Test::More tests => 2;

use Acme::Lvalue [succ => sub { $_[0] + 1 }, sub { $_[0] - 1 }], qw(:builtins);

my $x;
succ(succ($x)) = 4;
is $x, 2;

length(sqrt($x)) = 5;
is $x, '1.999396';
