#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'XML::LibXSLT::Easy',
    VERSION_FROM => 'lib/XML/LibXSLT/Easy.pm',
    INSTALLDIRS  => 'site',
    SIGN         => 1,
    PL_FILES     => { },
    PREREQ_PM    => {
        'Test::use::ok' => 0,
        'Moose' => 0,
        'MooseX::Types::VariantTable' => 0,
        'XML::LibXML' => 0,
        'XML::LibXSLT' => 0,
        'Test::XML' => 0,,
        'namespace::clean' => '0.08',
        'MooseX::Types::Path::Class' => 0,
        'Path::Class' => 0,
        'MooseX::Types::Moose' => 0,
        'MooseX::Types::URI' => 0,
        'Devel::PartialDump' => 0,
    },
);

