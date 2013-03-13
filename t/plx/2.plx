use Test::More tests => 1;
use strict;
use warnings;

ok(1, "dsn:$ENV{PERL_TEST_MYSQLPOOL_DSN}");
