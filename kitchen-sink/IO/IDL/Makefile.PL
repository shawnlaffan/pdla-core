use ExtUtils::MakeMaker;
use strict;
use warnings;

# With dmake a postamble is sometimes (incorrectly) written
# in the Makefile. The following prevents that:
undef &MY::postamble; # suppress warning
*MY::postamble = sub { return ""; };

WriteMakefile(
     NAME => "PDLA::IO::IDL",
     'VERSION_FROM' => '../../Basic/Core/Version.pm',
    (eval ($ExtUtils::MakeMaker::VERSION) >= 6.57_02 ? ('NO_MYMETA' => 1) : ()),
);
