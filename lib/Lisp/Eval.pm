package Lisp::Eval;

use strict;
use vars qw($DEBUG);

use Lisp::Symbol qw(symbol symbolp);

my $macro  = symbol("macro");
my $lambda = symbol("lambda");
my $nil    = symbol("nil");

# symbols in the argument list
my $opt    = symbol("&optional");
my $rest   = symbol("&rest");

sub eval
{
    my $form = shift;
    print "EVAL: ", Lisp::Printer::print($form), "\n" if $DEBUG;

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
		    $_ = Lisp::Eval::eval($_);
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
	    my $str = Lisp::Printer::print($func);
	    die "invalid-list-function ($str)";
	}
    } else {
	my $str = Lisp::Printer::print($func);
	die "invalid-function ($str)";
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
	$res = Lisp::Eval::eval($lambda->[$pc]);
	$pc++;
    }
    $res;
}



symbol("+")->function(sub { my $sum=shift; for (@_) {$sum+=$_} $sum });
symbol("*")->function(sub { my $prod=shift; for (@_) {$prod*=$_} $prod});
symbol("-")->function(sub { return -$_[0] if @_ == 1; my $sum = shift; for(@_) {$sum-=$_} $sum});

symbol("set")->function(sub {$_[0]->value($_[1]); $_[1]} );
symbol("quote")->function(bless sub {$_[0]}, "Lisp::Special");
symbol("setq")->function(bless sub{my $val = Lisp::Eval::eval($_[1]); $_[0]->value($val); $val}, "Lisp::Special");

symbol("progn")->function(sub {$_[-1]});
symbol("prog1")->function(sub {$_[0]});
symbol("prog2")->function(sub {$_[1]});
symbol("list")->function(sub {[@_]});

symbol("fset")->function(sub {$_[0]->function($_[1]); $_[1]});
symbol("symbol-function")->function(sub {$_[0]->function});

symbol("defun")->function(
bless sub {
    my $sym = shift;
    $sym->function([$lambda, @_]);
    $sym;
}, "Lisp::Special"
);


symbol("p")->function(sub{print join("\n", (map Lisp::Printer::print($_), @_), "")});

symbol("let")->function(
bless
sub {
   my $bindings = shift;
   my @bindings = @$bindings;  # make a copy

   # First evaluate all bindings as variables
   for my $b (@bindings) {
       if (symbolp($b)) {
	   $b = [$b, $nil];
       } else {
	   my($sym, $val) = @$b;
	   $val = $val->value if $val && symbolp($val);
	   $b = [$sym, $val];
       }
   }
   
   # Then localize
   require Lisp::Localize;
   my $local = Lisp::Localize->new;
   for my $b (@bindings) {
       $local->save_and_set(@$b);
   }

   my $res;
   for (@_) {
       $res = Lisp::Eval::eval($_);
   }
   $res;
}, "Lisp::Special");

symbol("let*")->function(
bless
sub {
   my $bindings = shift;
   require Lisp::Localize;
   my $local = Lisp::Localize->new;

   # Evaluate and localize in the order given
   for my $b (@$bindings) {
       if (symbolp($b)) {
	   $local->save_and_set($b, $nil);
       } else {
	   my($sym, $val) = @$b;
	   $val = $val->value if $val && symbolp($val);
	   $local->save_and_set($sym, $val);
       }
   }
   my $res;
   for (@_) {
       $res = Lisp::Eval::eval($_);
   }
   $res;
}, "Lisp::Special");

symbol("put")->function(sub{$_[0]->put($_[1] => $_[2])});
symbol("get")->function(sub{$_[0]->get($_[1])});


# Make many perl functions available from the lisp envirionment
my @code;

# Perl builtins that take one optional argument
for (qw(sin cos exp localtime gmtime stat caller length -s -e -f)) {
    push(@code, qq(symbol("$_")->function(sub { \@_==0?$_:$_ \$_[0] });\n));
}

# Perl builtins that does take zero arguments
for (qw(time times getlogin getppid fork wait)) {
    push(@code, qq(symbol("$_")->function(sub { $_ });\n));
}
	

print join("", @code) if $DEBUG;
eval join("", @code);
die $@ if $@;

1;
