package App::Prove::Plugin::MySQLPool;
use Mouse;
use Cache::FastMmap;
use File::Temp qw/tempdir/;
use POSIX::AtFork;
use Test::mysqld::Pool;

our $VERSION = '0.01';

# prove -PMySQLPool=Test::MyApp::DB -j4 t
# 1. launches 4 Test::mysqld-s
# 2. runs `Test::MyApp::DB->prepare( $mysqld )` for each instances
# 3. inflates $ENV{ PERL_TEST_MYSQLPOOL_DSN } for each test

sub load {
    my ($class, $prove) = @_;
    my @args     = @{ $prove->{args} };
    my $preparer = $args[ 0 ];
    my $jobs     = $prove->{ app_prove }->jobs || 1;

    my $share_file = File::Temp->new();

    my $pool       = Test::mysqld::Pool->new(
        jobs       => $jobs,
        share_file => $share_file->filename,
        ($preparer ? ( preparer => sub {
            my ($mysqld) = @_;
            Mouse::Util::load_class( $preparer );
            $preparer->prepare( $mysqld );
        } ) : ()),
    );
    $pool->prepare;

    $prove->{ app_prove }{ __PACKAGE__ } = [ $pool, $share_file ]; # ref++

    $ENV{ PERL_APP_PROVE_PLUGIN_MYSQLPOOL_SHARE_FILE } = $share_file->filename;

    POSIX::AtFork->add_to_child( \&child_hook );

    $prove->{app_prove}->formatter('TAP::Formatter::MySQLPool');

    1;
}

sub child_hook {
    my ($call) = @_;

    # we're in the test process

    # prove uses 'fork' to create child processes
    # our own 'ps -o pid ...' uses 'backtick'
    # only hook 'fork'
    ($call eq 'fork')
        or return;

    my $share_file = $ENV{ PERL_APP_PROVE_PLUGIN_MYSQLPOOL_SHARE_FILE }
        or return;

    my $dsn = Test::mysqld::Pool->new( share_file => $share_file )->alloc;

    # use this in tests
    $ENV{ PERL_TEST_MYSQLPOOL_DSN } = $dsn;
}

{
    package TAP::Formatter::MySQLPool::Session;
    use parent 'TAP::Formatter::Console::Session';

    sub close_test {
        my $self = shift;

        my $share_file = $ENV{ PERL_APP_PROVE_PLUGIN_MYSQLPOOL_SHARE_FILE }
            or return;
        Test::mysqld::Pool->new( share_file => $share_file )->dealloc_unused;

        $self->SUPER::close_test(@_);
    }
}

{
    package TAP::Formatter::MySQLPool;
    use parent 'TAP::Formatter::Console';

    sub open_test {
        my $self = shift;

        bless $self->SUPER::open_test(@_), 'TAP::Formatter::MySQLPool::Session';
    }
}

1;
__END__

=head1 NAME

App::Prove::Plugin::MySQLPool -

=head1 SYNOPSIS

  use App::Prove::Plugin::MySQLPool;

=head1 DESCRIPTION

App::Prove::Plugin::MySQLPool is

=head1 AUTHOR

Masakazu Ohtsuka E<lt>o.masakazu@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
