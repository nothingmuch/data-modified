#!/usr/bin/perl

package Data::Modified;

use strict;
use warnings;

BEGIN {
	our $VERSION = '0.01';

	local $@;

	eval {
		require XSLoader;
		__PACKAGE__->XSLoader::load($VERSION);
		1;
	} or do {
		warn $@;
		require DynaLoader;
		push our @ISA, 'DynaLoader';
		__PACKAGE__->bootstrap($VERSION);
	};
}

use Sub::Exporter -setup => {
	exports => [qw(track untrack)],
	groups => { default => [-all] },
};

__PACKAGE__

__END__

=pod

=head1 NAME

Data::Modified - Keep track of whether data is modified.

=head1 SYNOPSIS

	use Data::Modified;

	my $modified;
	track( $var, \$modified );

	# time passes

	warn "$var has been changed $modified times";


	# can also use a sub
	track( $var, sub { ... } );


	# or an array reference
	track( $var, \@array );

	untrack( $var, \@array ); # remove a tracking var like this



	# the third arg is "only once"
	# if true, the magic will be removed after it fires the first time
	track( $var, \$modified, 1 );


	# recursively check for changes
	use Data::Visitor::Callback;

	Data::Visitor::Callback->new(
		ignore_return_values => 1,
		visit => sub { track($_, \$modified, 1) },
	)->visit( $some_data );

	# time passes

	if ( $modified ) {
		warn "Something in $some_data has changed";
	}

=head1 DESCRIPTION

This module applies set magic to Perl data structures and tracks changes to
that data.

=head1 EXPORTS

See L<Sub::Exporter>.

=over 4

=item track $data, $listener, [ $once ]

Adds magic to $data, pointing to $listener.

The magic is actually applied to the referant of $data. If it isn't a reference
the behavior is as if a scalar reference was used.

Whenever the referant of $data is changed, $listener will be updated as
follows:

If it's an array reference, $data is pushed into it.

If it's a code ref it will be invoked with $data.

Otherwise, $$listener is incremented.

=item untrack $data, $listener

Remove $listener as a listener of $data.

=back

=head1 TODO

Hashes are not yet working, I need to implement the UVAR magic for that to
happen and it's a PITA. Next release...

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/code>, and use C<darcs send> to commit
changes.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
