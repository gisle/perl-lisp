print "1..2\n";

use Lisp::Reader  qw(lisp_read);
use Lisp::Printer qw(lisp_print);

$form = lisp_read("a b (a b)");

print "not " unless @$form == 3 &&
                    $form->[0]->name eq "a" &&
                    $form->[1]->name eq "b" &&
                    $form->[2][0]->name eq "a";
print "ok 1\n";

print lisp_print($form), "\n";
print "not " unless lisp_print($form) eq "(a b (a b))";
print "ok 2\n";

