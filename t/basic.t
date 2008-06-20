#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::XML;

use Path::Class;

use ok 'XML::LibXSLT::Easy';


my $xmldir = file(__FILE__)->parent->subdir("xml");


my $t = XML::LibXSLT::Easy->new;

isa_ok( $t, "XML::LibXSLT::Easy" );

isa_ok( $t->xml, "XML::LibXML" );

isa_ok( $t->xslt, "XML::LibXSLT" );

my $xml = $t->process( xml => $xmldir->file("foo.xml"), xsl => $xmldir->file("foo.xsl") );

ok($xml, "got some xml");

is_xml( $xml, <<XML, "processed correctly" );
<?xml version="1.0"?>
<div class="blart">
    <div id="panel_0" class="upper"><h3>foo</h3></div>
    <div id="panel_1" class="upper"><h3>bar</h3></div>
</div>
XML
