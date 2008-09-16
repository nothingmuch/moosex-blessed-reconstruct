#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'MooseX::Blessed::Reconstruct',
	VERSION_FROM => 'lib/MooseX/Blessed/Reconstruct.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Test::use::ok' => 0,
		'namespace::clean' => 0,
		'Moose' => 0,
		'Class::MOP' => 0.66,
		'Data::Visitor' => 0.21,
	},
);

