package Lisp::Vector;

sub new
{
    my $class = shift;
    bless [@_], $class;
}

1;
