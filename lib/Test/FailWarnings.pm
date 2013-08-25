use 5.008001;
use strict;
use warnings;

package Test::FailWarnings;
# ABSTRACT: Add test failures if warnings are caught
# VERSION

use Test::More 0.86;
use Carp;
use Cwd ();

our $ALLOW_DEPS = 0;
our @ALLOW_FROM = ();

sub import {
    my ( $class, @args ) = @_;
    croak("import arguments must be key/value pairs")
      unless @args % 2 == 0;
    my %opts = @args;
    $ALLOW_DEPS = $opts{'-allow_deps'};
    if ( $opts{'-allow_from'} ) {
        @ALLOW_FROM =
          ref $opts{'-allow_from'} ? @{ $opts{'-allow_from'} } : $opts{'-allow_from'};
    }
    $SIG{__WARN__} = \&handler;
}

sub handler {
    my $msg = shift;
    $msg = '' unless defined $msg;
    chomp $msg;
    my ( $package, $filename, $line ) = _find_source();

		# If the filename is absolute, make it relative if the file is in the
		# current path. This allows properly detecting "local" dependencies.
		if ( $filename =~ /^(?:\/|[a-z]:\\)/i ) {
			my $directory = Cwd::getcwd();
			$filename =~ s/^\Q$directory\E[\\\/]//;
		}

    # shortcut if ignoring dependencies and warning did not
    # come from something local
    return if $ALLOW_DEPS && $filename !~ /^(?:t|xt|lib|blib)/;

    return if grep { $package eq $_ } @ALLOW_FROM;

    if ( $msg !~ m/at .*? line \d/ ) {
        chomp $msg;
        $msg = "'$msg' at $filename line $line.";
    }
    else {
        $msg = "'$msg'";
    }
    my $builder = Test::More->builder;
    $builder->ok( 0, "Test::FailWarnings should catch no warnings" )
      or $builder->diag("Warning was $msg");
}

sub _find_source {
    my $i = 1;
    while (1) {
        my ( $pkg, $filename, $line ) = caller( $i++ );
        return caller( $i - 2 ) unless defined $pkg;
        next if $pkg =~ /^(?:Carp|warnings)/;
        return ( $pkg, $filename, $line );
    }
}

1;

=for Pod::Coverage handler

=head1 SYNOPSIS

Test file:

    use strict;
    use warnings;
    use Test::More;
    use Test::FailWarnings;

    ok( 1, "first test" );
    ok( 1 + "lkadjaks", "add non-numeric" );

    done_testing;

Output:

    ok 1 - first test
    not ok 2 - Caught warning
    #   Failed test 'Caught warning'
    #   at t/bin/main-warn.pl line 7.
    # Warning was 'Argument "lkadjaks" isn't numeric in addition (+) at t/bin/main-warn.pl line 7.'
    ok 3 - add non-numeric
    1..3
    # Looks like you failed 1 test of 3.

=head1 DESCRIPTION

This module hooks C<$SIG{__WARN__}> and converts warnings to L<Test::More>'s
C<fail()> calls.  It is designed to be used with C<done_testing>, when you
don't need to know the test count in advance.

Just as with L<Test::NoWarnings>, this does not catch warnings if other things
localize C<$SIG{__WARN__}>, as this is designed to catch I<unhandled> warnings.

=head1 USAGE

=head2 Overriding C<$SIG{__WARN__}>

On C<import>, C<$SIG{__WARN__}> is replaced with
C<Test::FailWarnings::handler>.

    use Test::FailWarnings;  # global

If you don't want global replacement, require the module instead and localize
in whatever scope you want.

    require Test::FailWarnings;

    {
        local $SIG{__WARN__} = \&Test::FailWarnings::handler;
        # ... warnings will issue fail() here
    }

When the handler reports on the source of the warning, it will look past
any calling packages starting with C<Carp> or C<warnings> to try to detect
the real origin of the warning.

=head2 Allowing warnings from dependencies

If you want to ignore failures from outside your own code, you can set
C<$Test::FailWarnings::ALLOW_DEPS> to a true value.  You can
do that on the C<use> line with C<< -allow_deps >>.

    use Test::FailWarnings -allow_deps => 1;

When true, warnings will only be thrown if they appear to originate from a filename
matching C<< qr/^(?:t|xt|lib|blib)/ >>

=head2 Allowing warnings from specific modules

If you want to white-list specific modules only, you can add their package
names to C<@Test::NoWarnings::ALLOW_FROM>.  You can do that on the C<use> line
with C<< -allow_from >>.

    use Test::FailWarnings -allow_from => [ qw/Annoying::Module/ ];

=head1 SEE ALSO

=for :list
* L<Test::NoWarnings> -- catches warnings and reports in an C<END> block.  Not (yet) friendly with C<done_testing>.
* L<Test::Warnings> -- a replacement for Test::NoWarnings that works with done_testing
* L<Test::Warn> -- test for warnings without triggering failures from this modules

=cut

# vim: ts=4 sts=4 sw=4 et:
