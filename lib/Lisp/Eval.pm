package Lisp::Eval;

use strict;
use vars qw($DEBUG);

sub eval
{
    my $form = shift;
    print "EVAL: ", Lisp::Printer::print($form), "\n" if $DEBUG;

    my $res = $form;
    $res;
}

1;
