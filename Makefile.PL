use inc::Module::Install;
name 'App-Prove-Plugin-MySQLPool';
all_from 'lib/App/Prove/Plugin/MySQLPool.pm';

requires 'App::Prove';
requires 'Cache::FastMmap';
requires 'File::Temp';
requires 'Mouse';
requires 'parent';
requires 'POSIX::AtFork';
requires 'Test::mysqld';

tests 't/*.t';
author_tests 'xt';

test_requires 'DBD::mysql';
test_requires 'DBI';
test_requires 'Test::Requires';

auto_set_repository;
WriteAll;
