use Test::More;
use strict;
use warnings;

use t::Util;

my $out = run_test({
    tests => [ 't/plx/1.plx', 't/plx/2.plx' ],
});
exit_status_is( 0 );

my (@dsns) = ( $out =~ m!dsn:(.+)$!gm );

is( (scalar @dsns), 2 );
isnt( $dsns[ 0 ], $dsns[ 1 ] );

done_testing;
