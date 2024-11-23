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
use P6::IO       ();
use P6::Template ();
use P6::Util     ();

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

sub children() {
    my $self = shift;
    my $dir  = shift;

    my $children = [grep { !/test|debug-/ } @{P6::IO::scan( $dir, qr/\.sh$|\.zsh$/, files_only => 1 )}];

    P6::Util::debug("DIR: $dir\n");
    P6::Util::debug_dumper( "CHILDREN: ", $children );

    $children;
}

sub parse {
    my $self = shift;

    my $funcs      = {};
    my $aliases    = {};
    my $module_dir = $self->module();

    if ( -e "$module_dir/init.zsh" ) {
        my $lines = P6::IO::dread("$module_dir/init.zsh");

        foreach my $line (@$lines) {
            if ( $line =~ /p6_alias "([^"]+)" ["']([^"]+)["']/ ) {
                my ( $from, $to ) = ( $1, $2 );
                $aliases->{$from} = $to;
            }
        }
    }

    my $children = $self->children($module_dir);

    foreach my $file ( sort @$children ) {
        my $lines = P6::IO::dread($file);

        foreach my $line (@$lines) {
            if ( $line =~ /# Function: (.*)/ ) {
                my $func   = $1;
		next if $func =~ /__/; ## internal/debug
                my $subdir = File::Basename::dirname $file;

                $subdir =~ s!$module_dir/lib/!!;
                P6::Util::debug("SUBDIR2: $subdir\n");

                push @{ $funcs->{$subdir}->{$file} }, $func;
            }
        }
    }

    foreach my $dir (keys %{$funcs}) {
        foreach my $file (keys %{$funcs->{$dir}}) {
            my @sorted_funcs = sort @{$funcs->{$dir}{$file}};
            $funcs->{$dir}{$file} = \@sorted_funcs;
        }
    }

    $self->aliases($aliases);
    $self->funcs($funcs);

    return;
}

sub readme_gen() {
    my $self = shift;
    my %args = @_;

    my $omodule = $self->module();
    my $aliases = $self->aliases();
    my $funcs   = $self->funcs();
    my $path    = $self->tmpl();
    my $module  = File::Basename::basename($omodule);

    my $hier = qx/cd $module ; tree -I node_modules -I cdktf.out -I cdk.out -I coverage -I tsconfig.tsbuildinfo/;

    my $data = {
        aliases => $aliases,
        funcs   => $funcs,
        module  => $module,
        hier    => $hier,
    };

    my $rv = P6::Template->render(
        $data,
        %args,
        paths  => $self->tmpl_paths(),
        ifile  => $self->tmpl(),
        output => "$module/" . $self->output(),
    );

    return $rv;
}

sub output     { "README.md" }
sub tmpl_paths { "$ENV{PERL5LIB}/../../tt" }
sub tmpl       { "readme/readme.md.tt" }
1;
