package Lisp::Subr::Perl;

# Make many perl functions available in the lisp envirionment

use strict;
use Lisp::Symbol qw(symbol);

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
