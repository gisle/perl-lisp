package Gnus::Newsrc;

use strict;
use vars qw($VERSION);

$VERSION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

use Lisp::Reader qw(lisp_read);


sub new
{
    my($class, $file) = @_;
    $file = "$ENV{HOME}/.newsrc.eld" unless defined $file;
    local($/) = undef;  #slurp;
    open(LISP, $file) || die "Can't open $file: $!";
    my $lisp = <LISP>;
    close(LISP);

    local $Lisp::Reader::SYMBOLS_AS_STRINGS = 1;  # gives quicker parsing
    my $form = lisp_read($lisp);

    my $self = bless {}, $class;

    for (@$form) {
	my($one,$two,$three) = @$_;
	#print join(" - ", map {$_->name} $one, $two), "\n";
	if ($one eq "setq") {
	    if (ref($three) eq "ARRAY") {
		my $first = $three->[0];
		if ($first eq "quote") {
		    $three = $three->[1];
		}
	    }
	    $self->{$two} = $three;
	} else {
	    warn "$_ does not start with (setq symbo ...)\n";
	}
    }

    # make the 'gnus-newsrc-alist' into a more perl suitable structure
    for (@{$self->{'gnus-newsrc-alist'}}) {
	my($group, $level, $read, $marks, $server, $para) = @$_;

	for ($read, $marks, $para) {
	    $_ = [] unless defined;
	}
	$_->[2] = join(",", map {ref($_)?"$_->[0]-$_->[1]":$_} @$read);
	$_->[3] = @$marks ?
                     { map {shift(@$_) =>
		            join(",", map {ref($_)?"$_->[0]-$_->[1]":$_}@$_)}
                      @$marks
                     }
                  : undef;
	$_->[5] = @$para ? { map { $_->[0] => $_->[1] } @$para } : undef;

	# trim trailing undef values
	pop(@$_) until defined($_->[-1]) || @$_ == 0;
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

sub alist_hash
{
    my $self = shift;
    unless ($self->{'_alist_hash'}) {
	my %ahash;
	$self->{'_alist_hash'} = \%ahash;
	for (@{$self->alist}) {
	    my @groupinfo = @$_;
	    my $group = shift @groupinfo;
	    $ahash{$group} = \@groupinfo;
	}
    }
    $self->{'_alist_hash'};
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
