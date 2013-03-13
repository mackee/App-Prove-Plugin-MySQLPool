package t::Util;
use strict;
use warnings;
use utf8;
use parent qw/Exporter/;

use App::Prove;
use Test::More;
use File::Temp qw/ tempfile /;

our @EXPORT = qw/run_test/;

# thanks to http://cpansearch.perl.org/src/TOKUHIROM/Test-Pretty-0.24/t/Util.pm
sub run_test {
    my (@tests) = @_;

    my ($tmp, $filename) = tempfile();
    close $tmp;

    my $pid = fork;
    die $! unless defined $pid;
    if ($pid) {
        waitpid($pid, 0);

        open my $fh, '<', $filename or die $!;
        my $out = do { local $/; <$fh> };
        close $fh;
        note 'x' x 80;
        note $out;
        note 'x' x 80;

        return $out;
    } else {
        # child
        open(STDOUT, ">", $filename) or die "Cannot redirect";
        open(STDERR, ">", $filename) or die "Cannot redirect";

        my $prove = App::Prove->new();
        $prove->process_args( '--norc',
                              '-v',
                              '-PMySQLPool',
                              '-j'.(scalar @tests),
                              @tests );
        $prove->run();
        exit;
    }
}

1;
