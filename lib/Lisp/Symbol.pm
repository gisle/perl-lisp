package Lisp::Symbol;
use strict;
use vars qw(@EXPORT_OK %obarray);

require Carp;
require Exporter;
*import = \&Exporter::import;
@EXPORT_OK = qw(symbol symbolp);

#use overload '""' => \&name;

%obarray = ();

my $t = symbol("t");
$t->value($t);

my $nil = symbol("nil");
$nil->value(undef);

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
    $obarray{$name} = bless {'name' => $name}, $class;
}

sub name
{
    $_[0]->{'name'};  # readonly
}

sub value
{
    my $self = shift;
    if (defined(wantarray) && !exists $self->{'value'}) {
	Carp::croak("Symbol's value as variable is void ($self->{'name'})");
    }
    my $old = $self->{'value'};
    $self->{'value'} = shift if @_;
    $old;
}

sub function
{
    my $self = shift;
    if (defined(wantarray) && !exists $self->{'function'}) {
	Carp::croak("Symbol's value as function is void ($self->{'name'})");
    }
    my $old = $self->{'function'};
    $self->{'function'} = shift if @_;
    $old;
}

sub plist
{
    my $self = shift;
    my $old = $self->{'plist'};
    $self->{'plist'} = shift if @_;
    $old;
}

sub get
{
    my $self = shift;
    $self->{'plist'}{$_[0]};
}

sub put
{
    my $self = shift;
    $self->{'plist'}{$_[0]} = $_[1];
}

1;
