print "1..2\n";

use Lisp::Reader;
use Lisp::Printer;

$form = Lisp::Reader::read("a b (a b)");

print "not " unless @$form == 3 &&
                    $form->[0]->name eq "a" &&
                    $form->[1]->name eq "b" &&
                    $form->[2][0]->name eq "a";
print "ok 1\n";

print Lisp::Printer::print($form), "\n";
print "not " unless Lisp::Printer::print($form) eq "(a b (a b))";
print "ok 2\n";

