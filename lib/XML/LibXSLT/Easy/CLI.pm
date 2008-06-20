#!/usr/bin/perl

package XML::LibXSLT::Easy::CLI;
use Moose;

use XML::LibXSLT::Easy;

with qw(MooseX::Getopt);

use MooseX::Types::Path::Class;

has [qw(xml xsl out)] => (
    isa => "Path::Class::File",
    is  => "rw",
    coerce   => 1,
    required => 1,
);


has out => (
    isa => "Path::Class::File",
    is  => "rw",
    coerce => 1,
);

has proc => (
    isa => "XML::LibXSLT::Easy",
    is  => "rw",
    lazy_build => 1,
);

sub _build_proc {
    XML::LibXSLT::Easy->new;
}

sub run {
    my $self = shift;
    $self = $self->new_with_options unless ref $self;

    $self->proc->process(
        input   => $self->xml,
        xsl     => $self->xsl,
        output => ( $self->out || \*STDOUT ),
    );
}

__PACKAGE__

__END__

=pod

=head1 NAME

XML::LibXSLT::Easy::CLI - 

=head1 SYNOPSIS

	use XML::LibXSLT::Easy::CLI;

=head1 DESCRIPTION

=cut


