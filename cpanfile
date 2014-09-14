requires 'App::Prove';
requires 'Cache::FastMmap';
requires 'File::Temp';
requires 'Mouse';
requires 'POSIX::AtFork';
requires 'Test::mysqld';
requires 'parent';

on build => sub {
    requires 'DBD::mysql';
    requires 'DBI';
    requires 'ExtUtils::MakeMaker', '6.36';
    requires 'Test::Requires';
};
