package Lisp::Symbol;
use strict;
use vars qw(@EXPORT_OK);

require Exporter;
*import = \&Exporter::import;
@EXPORT_OK = qw(symbol symbolp);

#use overload '""' => \&name;

my %obarray;

sub symbol
{
    Lisp::Symbol->new(@_);
}

sub symbolp
{
    UNIVERSAL::isa($_[0], "Lisp::Symbol");
}

sub new
{
    my($class, $name) = @_;
    return $obarray{$name} if $obarray{$name};
    $obarray{$name} = bless \$name, $class;
}

sub name
{
    ${$_[0]}
}

1;
