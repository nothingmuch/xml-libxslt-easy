#!/usr/bin/perl

package XML::LibXSLT::Easy;
use Moose;

use Carp qw(croak);

use XML::LibXML;
use XML::LibXSLT;

use MooseX::Types::VariantTable::Declare;
use MooseX::Types::Moose qw(Str FileHandle Item Undef);
use MooseX::Types::Path::Class qw(File);
use MooseX::Types -declare => [qw(Stylesheet Document)];
use Moose::Util::TypeConstraints;

use namespace::clean -except => [qw(meta)];

has xml => (
    isa => "XML::LibXML",
    is  => "rw",
    lazy_build => 1,
    handles => [qw(
        parse_string
        parse_fh
        parse_file
    )],
);

has xml_options => (
    isa => "HashRef",
    is  => "rw",
    default => sub { {} },
);

sub _build_xml {
    my $self = shift;
    XML::LibXML->new( %{ $self->xml_options } );
}

has xslt=> (
    isa => "XML::LibXSLT",
    is  => "rw",
    lazy_build => 1,
    handles => [qw(
        parse_stylesheet
        transform
    )],
);

has xslt_options => (
    isa => "HashRef",
    is  => "rw",
    default => sub { {} },
);

sub process {
    my ( $self, %args ) = @_;

    my $doc = $self->parse($args{xml});

    my $stylesheet = $self->stylesheet( $args{xsl} );

    $self->output( $args{out}, $stylesheet, $stylesheet->transform($doc) );
}

sub _build_xslt {
    my $self = shift;
    XML::LibXSLT->new( %{ $self->xslt_options } );
}

class_type Stylesheet() => { class => "XML::LibXSLT::StylesheetWrapper" };
class_type Document()   => { class => "XML::LibXML::Document" };

variant_method stylesheet => Stylesheet() => sub { $_[1] };
variant_method stylesheet => Document() => "parse_stylesheet";
variant_method stylesheet => Item() => sub {
    my ( $self, $thing ) = @_;
    $self->stylesheet( $self->parse($thing) );
};

variant_method parse => Document() => sub { $_[1] };
variant_method parse => FileHandle() => "parse_fh";
variant_method parse => File() => "parse_file";
variant_method parse => Str() => sub {
    my ( $self, $thing, @args ) = @_;
    
    if ( -f $thing ) {
        $self->parse_file($thing, @args);
    } else {
        $self->parse_string($thing, @args);
    }
};

variant_method output => FileHandle() => "output_fh";
variant_method output => Str() => "output_file";
variant_method output => File() => "output_file";
variant_method output => Undef() => "output_string";

sub output_string {
    my ( $self, undef, $s, $r ) = @_;
    $s->output_string($r);
}

sub output_fh {
    my ( $self, $o, $s, $r ) = @_;
    $s->output_fh($r, $o);
}

sub output_file {
    my ( $self, $o, $s, $r ) = @_;
    $s->output_file($r, $o);
}

__PACKAGE__

__END__

=pod

=head1 NAME

XML:::LibXSLT::Easy - DWIM XSLT processing with L<XML::LibXSLT>

=head1 SYNOPSIS

	use XML:::LibXSLT::Easy;

    my $p = XML:::LibXSLT::Easy->new;

    my $output = $p->process( xml => "foo.xml", xsl => "foo.xsl" );

    # takes various types of arguments
    $p->process( xml => $doc, xsl => $filehandle, out => $filename );

=head1 DESCRIPTION

=cut


