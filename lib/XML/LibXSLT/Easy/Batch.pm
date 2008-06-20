#!/usr/bin/perl

package XML::LibXSLT::Easy::Batch;
use Moose;

use Carp qw(croak);

use XML::LibXSLT::Easy;

use File::Glob;

use MooseX::Types::Path::Class;

use namespace::clean -except => [qw(meta)];

has proc => (
    isa => "XML::LibXSLT::Easy",
    is  => "rw",
    lazy_build => 1,
    handles => { "process_file" => "process" },
);

sub _build_proc {
    XML::LibXSLT::Easy->new;
}

has files => (
    isa => "ArrayRef[HashRef[Str|Path::Class::File]]",
    is  => "ro",
    required => 1,
);

sub process {
    my ( $self, @files ) = @_;

    foreach my $entry ( @{ $self->files } ) {
        $self->process_entry(%$entry);
    }
}

sub process_entry {
    my ( $self, %args ) = @_;

    if ( -f $args{xml} and -f $args{xsl} ) {
        $self->process_file(%args);
    } elsif ( $args{xml} =~ /\*/ ) {
        $self->process_glob(%args);
    }
}

sub process_glob {
    my ( $self, %args ) = @_;

    my ( $xml_glob, $xsl_glob, $out_glob ) = @args{qw(xml xsl out)};

    ( $out_glob = $xml_glob ) =~ s/xml$/html/ unless $out_glob;
    ( $xsl_glob = $xml_glob ) =~ s/xml$/xsl/  unless $xsl_glob;

    # from Locale::Maketext:Lexicon
    my $pattern = quotemeta($xml_glob);
    $pattern =~ s/\\\*(?=[^*]+$)/\([-\\w]+\)/g or croak "bad glob: $xml_glob";
    $pattern =~ s/\\\*/.*?/g;
    $pattern =~ s/\\\?/./g;
    $pattern =~ s/\\\[/[/g;
    $pattern =~ s/\\\]/]/g;
    $pattern =~ s[\\\{(.*?)\\\\}][
        '(?:'.join('|', split(/,/, $1)).')'
    ]eg;

    foreach my $xml ( File::Glob::bsd_glob($xml_glob) ) {
        $xml =~ /$pattern/ or next;
        my $basename = $1;

        my ( $xsl, $out ) = ( $xsl_glob, $out_glob );

        s/\*/$basename/e for $xsl, $out;

        $self->process_file( xml => $xml, xsl => $xsl, out => $out );
    }
}

__PACKAGE__

__END__

=pod

=head1 NAME

XML::LibXSLT::Easy::Batch - 

=head1 SYNOPSIS

	use XML::LibXSLT::Easy::Batch;

=head1 DESCRIPTION

=cut


