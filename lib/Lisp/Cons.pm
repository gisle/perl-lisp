package Lisp::Cons;

# Only used to represent (a . b) cons cells.  The normal
# (a b c d) list is represented with a unblessed array [a,b,c,d]

sub new
{
    my($class, $car, $cdr) = @_;
    bless [$car, $cdr], $class;
}

sub car
{
    my $self = shift;
    my $old = $self->[0];
    $self->[0] = shift if @_;
    $old;
}

sub cdr
{
    my $self = shift;
    my $old = $self->[1];
    $self->[1] = shift if @_;
    $old;
}

1;
