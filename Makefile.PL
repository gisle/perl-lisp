require 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	 => 'perl-lisp',
    VERSION      => '0.04',
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
