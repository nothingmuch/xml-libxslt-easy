#!/usr/bin/perl

package XML::LibXSLT::Easy;
use Moose;

our $VERSION = "0.01";

use Carp qw(croak);

use Devel::PartialDump qw(warn dump);

use XML::LibXML;
use XML::LibXSLT;

use Path::Class;
use URI;
use URI::file;
use URI::data;

use Scope::Guard;

use MooseX::Types::VariantTable::Declare;
use MooseX::Types::Moose qw(Str FileHandle Item Undef);
use MooseX::Types::Path::Class qw(File);
use MooseX::Types::URI qw(Uri FileUri DataUri);

use MooseX::Types -declare => [qw(Stylesheet Document)];

use namespace::clean -except => [qw(meta)];

has xml => (
    isa => "XML::LibXML",
    is  => "rw",
    lazy_build => 1,
    handles => [qw(
        parse_string
        parse_fh
        parse_file
        base_uri
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

    my ( $xml, $xsl, $out, $uri ) = @args{qw(xml xsl out input_uri)};

    $uri ||= $self->get_uri($xml);

    my $doc = $self->parse($xml);

    if ( $uri and not is_DataUri($uri) ) {
        my $prev_base = $self->base_uri;
        my $sg = Scope::Guard->new(sub { $self->base_uri($prev_base) });
        $self->base_uri($uri);
    }

    unless ( defined $xsl ) {
        croak "Can't process <?xml-stylesheet> without knowing the URI of the input" unless $uri;
        $xsl = $self->get_xml_stylesheet_pi( $doc, $uri, %args );
    }

    my $stylesheet = $self->stylesheet($xsl);

    $self->output( $out, $stylesheet, $stylesheet->transform($doc) );
}

sub _build_xslt {
    my $self = shift;
    XML::LibXSLT->new( %{ $self->xslt_options } );
}

sub get_xml_stylesheet_pi {
    my ( $self, $doc, $uri, %args ) = @_;

    # from AxKit::PageKit::Content
    my @stylesheet_hrefs;
    for my $pi_node ($doc->findnodes('processing-instruction()')) {
        my $pi_str = $pi_node->getData;
        if ( $pi_str =~ m!type="text/xsl! or $pi_str !~ /type=/ ) {
            my ($stylesheet_href) = ($pi_str =~ m!href="([^"]*)"!);

            my $xsl_uri = URI->new($stylesheet_href);

            if ( $xsl_uri->scheme ) { # scheme means abs
                return $xsl_uri;
            } else {
                if ( $uri->isa("URI::data") ) {
                    croak "<?xml-stylesheet>'s href is relative but the base URI is in the 'data:' scheme and cannot be used as a base";
                }

                if ( $uri->isa("URI::file") ) {
                    my $file = file($uri->file);
                    return $file->parent->file($stylesheet_href);
                } elsif ( $uri->scheme ) {
                    return $xsl_uri->abs($uri)
                } else {
                    croak "<?xml-stylesheet>'s href is relative buit the URI base neither absolute nor a 'file:' one";
                }
            }
        }
    }

    croak "No <?xml-stylesheet> processing instruction in document, please specify stylesheet explicitly";
}

class_type Stylesheet() => { class => "XML::LibXSLT::StylesheetWrapper" };
class_type Document()   => { class => "XML::LibXML::Document" };

variant_method get_uri => Uri()  => sub { $_[1] };
variant_method get_uri => File() => sub { URI::file->new($_[1]) }; # FIXME wrong
variant_method get_uri => Str()  => sub {
    my ( $self, $str ) = @_;

    if ( -f $str ) {
        URI::file->new($str);
    } else {
        URI::data->new($str);
    }
};

variant_method get_uri => Item() => sub {
    my ( $self, @args ) = @_;
    croak "Don't know how to make a URI out of " . dump(@args);
};

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

variant_method parse => DataUri() => sub {
    my ( $self, $uri, @args ) = @_;
    $self->parse_string( $uri->data, @args );
};

# includes file URIs
variant_method parse => Uri() => sub {
    my ( $self, @args ) = @_;
    $self->parse_file( @args );
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

XML::LibXSLT::Easy - DWIM XSLT processing with L<XML::LibXSLT>

=head1 SYNOPSIS

    use XML:::LibXSLT::Easy;

    my $p = XML:::LibXSLT::Easy->new;

    my $output = $p->process( xml => "foo.xml", xsl => "foo.xsl" );

    # takes various types of arguments
    $p->process( xml => $doc, xsl => $filehandle, out => $filename );

=head1 DESCRIPTION

=cut


