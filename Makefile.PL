use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Rapid7::NeXpose::API',
    AUTHOR              => q{Vlatko Kosturjak <kost@linux.hr>},
    VERSION_FROM        => 'lib/Rapid7/NeXpose/API.pm',
    ABSTRACT_FROM       => 'lib/Rapid7/NeXpose/API.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Rapid7-NeXpose-API-*' },
);
