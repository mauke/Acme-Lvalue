package Acme::Lvalue;

use warnings;
use strict;

use v5.14.2;

*VERSION = \'0.02';

{
	package Acme::Lvalue::Proxy;

	sub TIESCALAR {
		my ($class, $ref, $func, $cnuf) = @_;
		bless [$ref, $func, $cnuf], $class
	}

	sub FETCH {
		my ($self) = @_;
		$self->[1]->(${$self->[0]})
	}

	sub STORE {
		my ($self, $val) = @_;
		my $ref = $self->[0];
		$$ref = $self->[2]->($val, $$ref);
	}

	sub UNTIE {}
	sub DESTROY {}
}

use Math::Trig;
use Carp qw(croak);

sub _export {
	my ($where, $what, $how, $woh) = @_;
	my $fun = sub ($) :lvalue {
		tie my $proxy, 'Acme::Lvalue::Proxy', \$_[0], $how, $woh;
		$proxy
	};
	no strict 'refs';
	*{$where . '::' . $what} = $fun;
}

our %builtins = map +($_->[0] => [eval "sub {scalar $_->[0] \$_[0]}", $_->[1]]),
	[chr       => sub { ord $_[0] }],
	[cos       => sub { acos $_[0] }],
	[defined   =>
		sub {
			$_[0]
				? defined $_[1]
					? $_[1]
					: 1
				: undef
		}
	],
	[exp       => sub { log $_[0] }],
	[hex       => sub { sprintf '%x', $_[0] }],
	[length    =>
		sub {
			my ($n, $x) = @_;
			my $l = length $x;
			$n <= $l
				? substr $x, 0, $n
				: $x . "\0" x ($n - $l)
		}
	],
	[log       => sub { exp $_[0] }],
	[oct       => sub { sprintf '%o', $_[0] }],
	[ord       => sub { chr $_[0] }],
	[quotemeta => sub { $_[0] =~ s/\\(.)/$1/sgr }],
	[reverse   => sub { scalar reverse $_[0] }],
	[sin       => sub { asin $_[0] }],
	[sqrt      => sub { my $x = shift; $x * $x }],
;

sub import {
	my $class = shift;
	my $caller = caller;

	for my $item (@_) {
		if (ref $item) {
			_export $caller, @$item;
		} elsif ($item eq ':builtins') {
			for my $f (keys %builtins) {
				_export $caller, $f, @{$builtins{$f}};
			}
		} elsif ($builtins{$item}) {
			_export $caller, $item, @{$builtins{$item}};
		} else {
			croak qq{"$item" is not exported by the $class module};
		}
	}
}

'ok'
__END__

=head1 NAME

Acme::Lvalue - Generalized lvalue subs

=head1 SYNOPSIS

    use Acme::Lvalue qw(:builtins)
    
    my $x;
    sqrt($x) = 3;  # $x == 9
    hex($x) = 212;  # $x eq "d4"
    $x = 2;
    length(sqrt($x)) = 5;  # $x == 1.999396

=head1 DESCRIPTION

=head1 AUTHOR

Lukas Mai, C<< <l.mai  at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2011-2012 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
