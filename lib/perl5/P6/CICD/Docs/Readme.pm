package P6::CICD::Docs::Readme;
use parent 'P6::Object';

## core
use strict;
use warnings FATAL => 'all';
use Carp;
use File::Basename ();

## Std

## CPAN

## Globals

## SDK
use P6::IO   ();
use P6::Util ();

## Constants

## methods

## private
sub _fields {

    {
        module  => "",
        funcs   => {},
        aliases => {},
    }
}

sub _post_init {
    my $self = shift;
    my %args = @_;

    $self->parse();
    $self->readme_gen();

    return;
}

sub readme_gen() {
    my $self = shift;
    my %args = @_;

    my $omodule = $self->module();
    my $module  = File::Basename::basename($omodule);

    print "# $module\n\n";

    print "## Table of Contents\n\n";
    print "
### $module
- [$module](#$module)
  - [Badges](#badges)
  - [Distributions](#distributions)
  - [Summary](#summary)
  - [Contributing](#contributing)
  - [Code of Conduct](#code-of-conduct)
  - [Usage](#usage)
  - [Author](#author)

### Badges

[![License](https://img.shields.io/badge/License-Apache%202.0-yellowgreen.svg)](https://opensource.org/licenses/Apache-2.0)
[![Gitpod ready-to-code](https://img.shields.io/badge/Gitpod-ready--to--code-blue?logo=gitpod)](https://gitpod.io/#https://github.com/p6m7g8/$module)
[![Mergify](https://img.shields.io/endpoint.svg?url=https://gh.mergify.io/badges/p6m7g8/$module/&style=flat)](https://mergify.io)
[![codecov](https://codecov.io/gh/p6m7g8/$module/branch/master/graph/badge.svg?token=14Yj1fZbew)](https://codecov.io/gh/p6m7g8/$module)
[![Known Vulnerabilities](https://snyk.io/test/github/p6m7g8/$module/badge.svg?targetFile=package.json)](https://snyk.io/test/github/p6m7g8/$module?targetFile=package.json)
[![Gihub repo dependents](https://badgen.net/github/dependents-repo/p6m7g8/$module)](https://github.com/p6m7g8/$module/network/dependents?dependent_type=REPOSITORY)
[![Gihub package dependents](https://badgen.net/github/dependents-pkg/p6m7g8/$module)](https://github.com/p6m7g8/$module/network/dependents?dependent_type=PACKAGE)

## Summary

## Contributing

- [How to Contribute](CONTRIBUTING.md)

## Code of Conduct

- [Code of Conduct](https://github.com/p6m7g8/.github/blob/master/CODE_OF_CONDUCT.md)

## Usage

";

    print "
### Aliases

";

    my $aliases = $self->aliases();
    foreach my $from ( sort keys %$aliases ) {
        my $to = $aliases->{$from};
        print "- $from -> $to\n";
    }

    print "
### Functions

";

    my $funcs = $self->funcs();

    foreach my $dir ( sort keys %$funcs ) {
        my $dir_funcs = $funcs->{$dir};

        foreach my $subdir ( sort keys %$dir_funcs ) {
            my $file_funcs = $dir_funcs->{$subdir};

            $subdir ||= $module;
            print "### $subdir:\n\n";

            foreach my $file ( sort keys %$file_funcs ) {
                next if $file =~ /debug/;
                next if $file =~ /\/_/;
                my @funcs = sort @{ $file_funcs->{$file} };

                my $pfile = $file;
                $file =~ s/^.*?$subdir/$subdir/;
                print "#### $file:\n\n";

                foreach my $func (@funcs) {
                    next if $func =~ /__/;
                    print "- $func\n";
                }

                print "\n";
            }

            print "\n";
        }

        print "\n";
    }

    if ( -d "$omodule/lib" ) {
        print "## Hier\n";
        print "```text\n";
        system "(cd $omodule/lib ; tree)";
        print "```\n";
    }

    print "## Author

Philip M . Gollucci <pgollucci\@p6m7g8.com>
";
    return;
}

sub children() {
    my $self = shift;
    my $dir  = shift;

    my $children = P6::IO::scan( $dir, qr/\.sh$|\.zsh$/, files_only => 1 );

    P6::Util::debug("DIR: $dir\n");
    P6::Util::debug_dumper( "CHILDREN: ", $children );

    $children;
}

sub dirs() {
    my $self = shift;

    my $module_dir = $self->module();
    my $lib_dir    = "$module_dir/lib";
    my $dirs       = [$lib_dir];

    P6::Util::debug("module_dir: $module_dir\n");
    P6::Util::debug("lib_dir: $lib_dir\n");
    P6::Util::debug_dumper( "DIRS", $dirs );

    $dirs;
}

sub parse {
    my $self = shift;

    my $funcs      = {};
    my $aliases    = {};
    my $module_dir = $self->module();
    my $dirs       = $self->dirs();

    if ( -e "$module_dir/init.zsh" ) {
        my $lines = P6::IO::dread("$module_dir/init.zsh");

        foreach my $line (@$lines) {
            if ( $line =~ /# Function: (.*)/ ) {
                push
                  @{ $funcs->{"$module_dir/lib"}->{""}->{"$module_dir/init.zsh"}
                  }, $1;
            }
            elsif ( $line =~ /p6_alias "([^"]+)" ["']([^"]+)["']/ ) {
                my ( $from, $to ) = ( $1, $2 );
                $aliases->{$from} = $to;
            }
        }
    }

    foreach my $dir ( sort @$dirs ) {
        my $children = $self->children($dir);

        foreach my $file ( sort @$children ) {
            my $lines = P6::IO::dread($file);

            foreach my $line (@$lines) {
                if ( $line =~ /# Function: (.*)/ ) {
                    my $func   = $1;
                    my $subdir = File::Basename::dirname $file;

                    $subdir =~ s!$module_dir/lib/!!;
                    P6::Util::debug("SUBDIR2: $subdir\n");

                    push @{ $funcs->{$dir}->{$subdir}->{$file} }, $func;
                }
            }
        }
    }

    $self->aliases($aliases);
    $self->funcs($funcs);

    return;
}

sub tmpl_paths { "$ENV{PERL5LIB}/../../tt" }

1;
