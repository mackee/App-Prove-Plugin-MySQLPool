use Test::More;
use strict;
use warnings;

use t::Util;

my $out = run_test({
    tests    => [ 't/plx/prepare.plx' ],
    preparer => 't::Util',
});
exit_status_is( 0 );

done_testing;
