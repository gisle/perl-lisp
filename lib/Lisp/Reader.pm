package Lisp::Reader;

use strict;
use vars qw($DEBUG);

use Lisp::Symbol qw(symbol);
#sub symbol { $_[0] }   # useful while debugging

sub read
{
    local($_) = shift;
    my $one   = shift;
    my $level = shift || 0;
    my $indent = "  " x $level;

    my @stack;
    my $form = [];

    if ($DEBUG) {
	print "${indent}Parse";
	print "-one" if $one;
	print ": $_\n";
    }
    
    while (1) {
	if (/\G\s*;+\s*(.*)/gc) {
	    print "${indent}COMMENT $1\n" if $DEBUG;
	} elsif (/\G\s*([()])/gc) {
	    print "${indent}PARA $1\n" if $DEBUG;
	    if ($1 eq "(") {
		my $prev = $form;
		push(@stack, $prev);
		push(@$prev, $form = []);
	    } else {
		last unless @stack;
		$form = pop(@stack);
		last if $one && !@stack;
	    }
	} elsif (/\G\s*([-+]?\d+(\.\d*)?)/gc) {  #
	    print "${indent}NUMBER $1\n" if $DEBUG;
	    push(@$form, $1);
	    last if $one && !@stack;
	} elsif (/\G\s*\"([^\"\\]*(?:\\.[^\"\\]*)*)\"/gc) {
	    my $str = $1;
	    $str =~ s/\\(.)/$1/g;
	    print "${indent}STRING $str\n" if $DEBUG;
	    push(@$form, $str);
	    last if $one && !@stack;
	} elsif (/\G\s*\'/gc) {
	    print "${indent}QUOTE\n" if $DEBUG;
	    my $old_pos = pos($_);
	    my($subform, $pos) = Lisp::Reader::read(substr($_, $old_pos), 1,
						    $level+1);
	    pos($_) = $old_pos + $pos;
	    push(@$form, [symbol("quote"), $subform]);
	    last if $one && !@stack;
	} elsif (/\G\s*([^\s();]+)/gc) {
	    print "${indent}SYMBOL $1\n" if $DEBUG;
	    push(@$form, symbol($1));
	    last if $one && !@stack;
	} elsif (/\G\s*\./gc) {
	    print "${indent}DOT\n" if $DEBUG;
	} elsif (/\G\s*(.)/gc) {
	    print "${indent}? $1\n";
	} else {
	    last;
	}
    }

    if ($one) {
	die "More than one form parsed, this should never happen"
	  if @$form > 1;
	$form = $form->[0];
    }

    wantarray ? ($form, pos($_)) : $form;
}

1;
