package Lisp::Subr::Core;

# implements the core subrs

use strict;
use Lisp::Symbol      qw(symbol);
use Lisp::Reader      qw(lisp_read);
use Lisp::Printer     qw(lisp_print);
use Lisp::Interpreter qw(lisp_eval);

my $lambda = symbol("lambda");
my $nil    = symbol("nil");

symbol("+")->function(sub { my $sum=shift; for (@_) {$sum+=$_} $sum });
symbol("*")->function(sub { my $prod=shift; for (@_) {$prod*=$_} $prod});
symbol("-")->function(
sub {
    return -$_[0] if @_ == 1;
    my $sum = shift; for(@_) {$sum-=$_}
    $sum
});

symbol("set")->function(sub {$_[0]->value($_[1]); $_[1]} );
symbol("quote")->function(bless sub {$_[0]}, "Lisp::Special");
symbol("setq")->function(bless sub{my $val = lisp_eval($_[1]); $_[0]->value($val); $val}, "Lisp::Special");

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
       $res = lisp_eval($_);
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
       $res = lisp_eval($_);
   }
   $res;
}, "Lisp::Special");

symbol("put")->function(sub{$_[0]->put($_[1] => $_[2])});
symbol("get")->function(sub{$_[0]->get($_[1])});


symbol("print")->function(sub{lisp_print($_[0])});
symbol("read")->function(sub{lisp_read($_[0])});

symbol("write")->function(sub{print join("\n", (map lisp_print($_), @_), "")});


1;
