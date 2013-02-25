use 5.008001;
use strict;
use warnings;

package Test::FailWarnings;
# ABSTRACT: Add test failures if warnings are caught
# VERSION

use Test::More 0.86;

$SIG{__WARN__} = sub {
    my $msg = shift;
    $msg = '' unless defined $msg;
    chomp $msg;
    my ($package, $filename, $line) = caller;
    if ( $msg !~ m/at .*? line \d/ ) {
        chomp $msg;
        $msg = "'$msg' at $filename line $line.";
    }
    else {
        $msg = "'$msg'";
    }
    my $builder = Test::More->builder;
    $builder->ok( 0, "Caught warning" )
        or $builder->diag("Warning was $msg");
};

1;

=for Pod::Coverage method_names_here

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

=head1 SEE ALSO

=for :list
* L<Test::NoWarnings> -- catches warnings and reports in an C<END> block.  Not (yet) friendly with C<done_testing>.
* L<Test::Warn> -- test for warnings without triggering failures from this modules

=cut

# vim: ts=4 sts=4 sw=4 et:
