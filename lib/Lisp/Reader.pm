package Lisp::Reader;

use strict;
use vars qw($DEBUG $SYMBOLS_AS_STRINGS @EXPORT_OK);

use Lisp::Symbol qw(symbol);

require Exporter;
*import = \&Exporter::import;
@EXPORT_OK = qw(lisp_read);


sub my_symbol
{
    $SYMBOLS_AS_STRINGS ? $_[0] : symbol($_[0]);
}

sub lisp_read
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
	if (/\G\s*;+([^\n]*)/gc) {
	    print "${indent}COMMENT $1\n" if $DEBUG;
	} elsif (/\G\s*([()\[\]])/gc) {
	    print "${indent}PARA $1\n" if $DEBUG;
	    if ($1 eq "(" or $1 eq "[") {
		my $prev = $form;
		push(@stack, $prev);
		push(@$prev, $form = []);
		bless $form, "Lisp::Vector" if $1 eq "[";
	    } else {
		last unless @stack;
		$form = pop(@stack);
		last if $one && !@stack;
	    }
	} elsif (/\G\s*([-+]?\d+(\.\d*)?)/gc) {  # XXX 3e4
	    print "${indent}NUMBER $1\n" if $DEBUG;
	    push(@$form, $1);
	    last if $one && !@stack;
	} elsif (/\G\s*\?([^\\])/gc) {
	    print "${indent}CHAR $1\n" if $DEBUG;
	    push(@$form, ord($1));
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
	    my($subform, $pos) = lisp_read(substr($_, $old_pos), 1, $level+1);
	    pos($_) = $old_pos + $pos;
	    push(@$form, [my_symbol("quote"), $subform]);
	    last if $one && !@stack;
	} elsif (/\G\s*\./gc) {
	    print "${indent}DOT\n" if $DEBUG;
	    bless $form, "Lisp::Cons";
	} elsif (/\G\s*([^\s()\[\];]+)/gc) {
	    print "${indent}SYMBOL $1\n" if $DEBUG;
	    push(@$form, my_symbol($1));
	    last if $one && !@stack;
	} elsif (/\G\s*(.)/gc) {
	    print "${indent}? $1\n";
	} else {
	    last;
	}
    }

    if (@stack) {
	warn "Form terminated early";  # or should we die?
	$form = $stack[0];
    }

    if ($one) {
	die "More than one form parsed, this should never happen"
	  if @$form > 1;
	$form = $form->[0];
    }

    wantarray ? ($form, pos($_)) : $form;
}

1;
