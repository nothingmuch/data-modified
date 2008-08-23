#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'Data::Modified';

{
	my $i = 0;

	my $changed = 0;

	Data::Modified::track($i, \$changed);

	is( $changed, 0, "no changes" );

	$i++;

	is( $changed, 1, "change counted" );

	$i++;

	is( $changed, 2, "change counted" );

	Data::Modified::untrack($i, \$changed);

	$i++;

	is( $changed, 2, "untrack works" );
}

{
	my $i = 0;

	my $changed = 0;

	Data::Modified::track($i, \$changed, 1);

	is( $changed, 0, "no changes" );

	$i++;

	is( $changed, 1, "change counted" );

	$i++;

	is( $changed, 1, "second change not counted" );
}

{
	my $i = 0;

	my @changed;

	Data::Modified::track($i, \@changed, 0);

	is_deeply( \@changed, [], "no changes" );

	$i++;

	is_deeply( \@changed, [ \$i ], "change noted" );

	$i++;

	is_deeply( \@changed, [ \$i, \$i ], "second change noted" );
}

{
	my $i = 0;

	my @changed;

	Data::Modified::track($i, sub { push @changed, $_[0] }, 0);

	is_deeply( \@changed, [], "no changes" );

	$i++;

	is_deeply( \@changed, [ \$i ], "change noted with sub" );

	$i++;

	is_deeply( \@changed, [ \$i, \$i ], "second change noted" );
}


{
	my @foo = qw(foo);

	my $changed = 0;

	Data::Modified::track(\@foo, \$changed, 0);

	is( $changed, 0, "no changes in array" );

	push @foo, "bar";

	is( $changed, 1, "change counted" );

	push @foo, "oi";

	is( $changed, 2, "change on sub element counted" );

	@foo = ();

	is( $changed, 3, "change on sub element counted" );

	Data::Modified::untrack(\@foo, \$changed);

	push @foo, undef;

	is( $changed, 3, "untrack works" );

	$foo[0] = "blah";

	is( $changed, 3, "no change in subelement" );
}

{
	my %foo = ( foo => 42 );

	my $changed = 0;

	Data::Modified::track(\%foo, \$changed, 0);

	is( $changed, 0, "no changes in hash" );

	$foo{foo}++;

	is( $changed, 0, "changing subelement doesn't affect hash" );

	local $TODO = "need UVAR magic... blah";

	delete $foo{foo};

	is( $changed, 1, "change counted" );

	$foo{foo}++;

	is( $changed, 2, "change counted" );

	@foo{qw(foo bar)} = qw(la la);

	is( $changed, 3, "change counted" );
}
