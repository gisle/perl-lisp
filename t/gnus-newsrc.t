if (-f "newsrc.eld") {
   print "1..4\n";
} else {
   print "1..0\n";
   exit;
}

use strict;
use Gnus::Newsrc_eld;

my $newsrc = Gnus::Newsrc_eld->new("newsrc.eld");

print "not " unless $newsrc->file_version eq "Gnus v5.5";
print "ok 1\n";

print "not " unless $newsrc->last_checked_date eq "Sat Oct 18 14:05:53 1997";
print "ok 2\n";

my $alist = $newsrc->alist;

my %ahash;
for (@$alist) {
    # my($group,$level,$read,$marks,$server,$para) = @$_;
    my $group = shift @$_;
    print "$group\n";
    $ahash{$group} = $_;
}

print "not " unless exists $ahash{"nnml+private:mail.perl"};
print "ok 3\n";

my $p5p = $ahash{"nnml+private:mail.perl"};
print "not " unless $p5p->[0] == 2 &&
                    $p5p->[1] eq "1-3667" &&
                    $p5p->[4]{'to-list'} eq "perl5-porters\@perl.org";
print "ok 4\n";

#use Data::Dumper;
#print Dumper($p5p);
