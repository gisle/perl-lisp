package Lisp::Interpreter;

use strict;
use vars qw($DEBUG @EXPORT_OK);

use Lisp::Symbol  qw(symbol symbolp);
use Lisp::Printer qw(lisp_print);

require Exporter;
*import = \&Exporter::import;
@EXPORT_OK = qw(lisp_eval);

my $macro  = symbol("macro");
my $lambda = symbol("lambda");
my $nil    = symbol("nil");

# symbols in the argument list
my $opt    = symbol("&optional");
my $rest   = symbol("&rest");

my $evalno = 0;

sub lisp_eval
{
    my $form = shift;
    my $no = ++$evalno;
    
    if ($DEBUG) {
	print "lisp_eval $evalno ", lisp_print($form), "\n";
    }

    return $form unless ref($form);  # a string or a number
    return $form->value if symbolp($form);

    my @args = @$form;
    my $func = shift(@args);

    while (symbolp($func)) {
	if ($func == $macro) {
	    shift(@args);
	    last;
	} elsif ($func == $lambda) {
	    last;
	} else {
	    $func = $func->function;
	}
    }

    unless (UNIVERSAL::isa($func, "Lisp::Special") || $func == $macro) {
	# evaluate all arguments
	for (@args) {
	    if (ref($_)) {
		if (symbolp($_)) {
		    $_ = $_->value;
		} elsif (ref($_) eq "ARRAY") {
		    $_ = lisp_eval($_);
		} else {
		    # leave it as it is
		}
	    }
	}
    }

    my $res;
    if (ref($func) eq "CODE" || UNIVERSAL::isa($func, "Lisp::Special")) {
	$res = &$func(@args);
    } elsif (ref($func) eq "ARRAY") {
	if ($func->[0] == $lambda) {
	    $res = lambda($func, \@args)
	} else {
	    my $str = lisp_print($func);
	    die "invalid-list-function ($str)";
	}
    } else {
	my $str = lisp_print($func);
	die "invalid-function ($str)";
    }
    if ($DEBUG) {
	my $str = lisp_print($res);
	print " $no ==> $str\n";
    }
    $res;
}


sub lambda  # calling a lambda expression
{
    my($lambda, $args) = @_;
    
    # set local variables
    require Lisp::Localize;
    my $local = Lisp::Localize->new;
    my $localvar = $lambda->[1];

    my $do_opt;
    my $do_rest;
    my $i = 0;
    for my $sym (@$localvar) {
	if ($sym == $opt) {
	    $do_opt++;
	} elsif ($sym == $rest) {
	    $do_rest++;
	} elsif ($do_rest) {
	    $local->save_and_set($sym, [ @{$args}[$i .. @$args-1] ] );
	    last;
	} elsif ($i < @$args || $do_opt) {
	    $local->save_and_set($sym, $args->[$i]);
	    $i++;
	} else {
	    die "too-few-arguments";
	}
    }
    if (!$do_rest && @$args > $i) {
	die "too-many-arguments";
    }

    # execute the function body
    my $res = $nil;
    my $pc = 2;  # starting here (0=lambda, 1=local variables)
    while ($pc < @$lambda) {
	$res = lisp_eval($lambda->[$pc]);
	$pc++;
    }
    $res;
}

1;
