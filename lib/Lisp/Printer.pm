package Lisp::Printer;

use Lisp::Symbol qw(symbolp);
use Lisp::Vector qw(vectorp);
use Lisp::Cons   qw(consp);

sub dump
{
    require Data::Dumper;
    Data::Dumper::Dumper($_[0]);
}

sub print
{
    my $obj = shift;
    my $str = "";
    if (ref($obj)) {
	if (symbolp($obj)) {
	    $str = $obj->name;
	} elsif (vectorp($obj)) {
	    $str = "[" . join(" ", map Lisp::Printer::print($_), @$obj) . "]";
	} elsif (consp($obj)) {
	    $str = "(" .join(" . ", map Lisp::Printer::print($_), @$obj). ")";
	} elsif (ref($obj) eq "ARRAY") {
	    $str = "(" . join(" ", map Lisp::Printer::print($_), @$obj) . ")";
	} elsif (ref($obj) eq "HASH") {
	    # make it into an alist
	    $str = "(" . join("",
			      map {"(" . Lisp::Printer::print($_) .
                                         " . " .
					 Lisp::Printer::print($obj->{$_}) .
                                    ")"
				  } sort keys %$obj) .
                   ")";
	} else {
	    $str = "#<$obj>";
	}
    } else {
	# XXX: need real number/string type info
	if (!defined($obj)) {
	    $str = "nil";
	} elsif ($obj =~ /^[+-]?\d+(?:\.\d*)?$/) {
	    # number
	    $str = $obj + 0;
	} else {
	    # string
	    $obj =~ s/([\"\\])/\\$1/g;  # quote special chars
	    $str = qq("$obj");
	}
    }
    $str;
}

1;
