package Lisp::Symbol;
use strict;
use vars qw(@EXPORT_OK);

require Exporter;
*import = \&Exporter::import;
@EXPORT_OK = qw(symbol);

my %obarray;

sub symbol
{
    Lisp::Symbol->new(@_);
}

sub new
{
    my($class, $name) = @_;
    return $obarray{$name} if $obarray{$name};
    $obarray{$name} = bless \$name, $class;
}

1;
