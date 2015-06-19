package Test::mysqld::Multi;

use warnings;
use strict;
use utf8;

use Test::mysqld;
use POSIX qw(SIGTERM WNOHANG);

sub start_mysqlds {
    my $class = shift;
    my $number = shift;
    my @args = @_;

    my @mysqlds = map { Test::mysqld->new(@args, auto_start => 0) } (1..$number);
    for my $mysqld (@mysqlds) {
        # (re)create directory structure
        mkdir $mysqld->base_dir;
        for my $subdir (qw/etc var tmp/) {
            mkdir $mysqld->base_dir . "/$subdir";
        }

        open my $logfh, '>>', $mysqld->base_dir . '/tmp/mysqld.log'
            or die 'failed to create log file:' . $mysqld->base_dir
                . "/tmp/mysqld.log:$!";
        my $pid = fork;
        die "fork(2) failed:$!" unless defined $pid;
        if ($pid == 0) {
            $mysqld->setup;

            open STDOUT, '>&', $logfh
                or die "dup(2) failed:$!";
            open STDERR, '>&', $logfh
                or die "dup(2) failed:$!";
            exec(
                $mysqld->mysqld,
                '--defaults-file=' . $mysqld->base_dir . '/etc/my.cnf',
                '--user=root',
            );
            die "failed to launch mysqld:$?";
        }
        close $logfh;
        $mysqld->pid($pid);
    }

    for my $mysqld (@mysqlds) {
        while (! -e $mysqld->my_cnf->{'pid-file'}) {
            if (waitpid($mysqld->pid, WNOHANG) > 0) {
                die "*** failed to launch mysqld ***\n" . $mysqld->read_log;
            }
            sleep 0.1;
        }

        # create 'test' database
        my $dbh = DBI->connect($mysqld->dsn(dbname => 'mysql'))
            or die $DBI::errstr;
        $dbh->do('CREATE DATABASE IF NOT EXISTS test')
            or die $dbh->errstr;
    }
    return @mysqlds;
}

sub stop_mysqlds {
    my $class = shift;
    my @mysqlds = @_;
    for my $mysqld (@mysqlds) {
        next unless $mysqld->pid;
        kill SIGTERM, $mysqld->pid;
    }
    for my $mysqld (@mysqlds) {
        while (waitpid($mysqld->pid, 0) <= 0) {
        }
        $mysqld->pid(undef);
    }
    return @mysqlds;
}

1;
