package P6::IO;
use parent 'P6';

## core
use strict;
use warnings FATAL => 'all';
use Carp;

## mp2

## libapreq2

## dist
use File::Find ();
use File::Copy ();

## cpan

## custom

## version
our $VERSION = q$Revision: 47160 $;

## constants

## globals

sub dread {
    my $f    = shift;
    my %args = @_;

    my @lines;
    if ( open my $fh, '<', $f ) {
        @lines = <$fh>;
        close $fh or die "Can't close [$f] b/c [$!]";
    }
    else {
        die "Can't open [$f] b/c [$!]" unless $args{nofail};
    }

    return \@lines;
}

sub dappend {
    my ( $f, $str ) = @_;

    open my $fh, '>>', $f or die "Can't open [$f] b/c [$!]";
    print $fh $$str;
    close $fh or die "Can't close [$f] b/c [$!]";

    return;
}

sub dwrite {
    my ( $f, $str ) = @_;

    open my $fh, '>', $f or die "Can't open [$f] b/c [$!]";
    print $fh $$str;
    close $fh or die "Can't close [$f] b/c [$!]";

    return;
}

sub scan {
    my ( $dir, $regex, %args ) = @_;

    my @files = ();
    return \@files unless -d $dir;

    File::Find::find sub {
        if ($regex) {
            return unless /$regex/;
        }
        if ( $args{files_only} ) {
            return if -d;
        }
        if ( $args{dirs_only} ) {
            return if !-d;
        }
        push @files, $File::Find::name;
    }, $dir;

    return \@files;
}

sub copy {
    my ( $f, $t ) = @_;

    File::Copy::copy( $f, $t ) or die "$f -> $t failed b/c [$!]\n";

    return;
}

1;
