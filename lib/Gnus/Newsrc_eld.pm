package Gnus::Newsrc_eld;

use strict;

use Lisp::Reader ();
use Lisp::Symbol qw(symbol symbolp);


sub new
{
    my($class, $file) = @_;
    $file = "$ENV{HOME}/.newsrc.eld" unless defined $file;
    local($/) = undef;  #slurp;
    open(LISP, $file) || die "Can't open $file: $!";
    my $lisp = <LISP>;
    close(LISP);
    my $form = Lisp::Reader::read($lisp);

    my $self = bless {}, $class;

    my $setq  = symbol("setq");
    my $quote = symbol("quote");

    for (@$form) {
	my($one,$two,$three) = @$_;
	#print join(" - ", map {$_->name} $one, $two), "\n";
	if ($one == $setq && symbolp($two)) {
	    if (ref($three) eq "ARRAY") {
		my $first = $three->[0];
		if (symbolp($first) && $first == $quote) {
		    $three = $three->[1];
		}
	    }
	    $self->{$two->name} = $three;
	} else {
	    warn "$_ does not start with (setq symbo ...)\n";
	}
    }

    use Data::Dumper;

    my $nil = symbol("nil");
    for (@{$self->{'gnus-newsrc-alist'}}) {
	my($group, $level, $read, $marks, $server, $para) = @$_;

	for ($read, $marks, $server, $para) {
	    $_ = [] if $_ == $nil;
	}

	$_->[2] = join(",", map {ref($_)?"$_->[0]-$_->[1]":$_} @$read);
	$_->[3] = { map {shift(@$_)->name =>
		        join(",", map {ref($_)?"$_->[0]-$_->[1]":$_}@$_)}
                   @$marks
                 };
	$_->[5] = { map { $_->[0]->name, $_->[1] } @$para };
    }

    $self;
}

sub file_version
{
    shift->{"gnus-newsrc-file-version"};
}

sub last_checked_date
{
    shift->{"gnus-newsrc-last-checked-date"};
}

sub alist
{
    shift->{"gnus-newsrc-alist"};
}

sub server_alist
{
    shift->{"gnus-server-alist"};

}

sub killed_list
{
    shift->{"gnus-killed-list"};
}

sub zombie_list
{
    shift->{"gnus-zombie-list"};
}

sub format_specs
{
    shift->{"gnus-format-specs"};
}

1;
