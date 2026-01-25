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
        hooks   => {},
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
    my $hooks      = {};
    my $module_dir = $self->module();
    my $module     = File::Basename::basename($module_dir);
    my $module_prefix = "p6df::modules::$module";

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
        my @file_funcs;
        my $current_func;
        my $current_args     = [];
        my $current_synopsis = [];
        my $in_args          = 0;
        my $in_synopsis      = 0;

        my $flush_func = sub {
            return unless $current_func;
            my $synopsis = join " ", grep { defined && length } @$current_synopsis;
            push @file_funcs,
              {
                name     => $current_func,
                args     => $current_args,
                synopsis => $synopsis,
              };
        };

        foreach my $line (@$lines) {
            if ( $line =~ /# Function: (.*)/ ) {
                $flush_func->();

                my $func   = $1;
                $in_args          = 0;
                $in_synopsis      = 0;
                $current_func     = undef;
                $current_args     = [];
                $current_synopsis = [];

                next if $func =~ /__/; ## internal/debug
                $current_func = $func;

                my $subdir = File::Basename::dirname $file;

                $subdir =~ s!$module_dir/lib/!!;
                P6::Util::debug("SUBDIR2: $subdir\n");

                if ( $func =~ /^\Q$module_prefix\E::(deps|init|home::symlinks|external::brew|langs|aliases::init|path::init|completions::init|vscodes|vscodes::config|prompt::init|prompt::mod)\(/ ) {
                    $hooks->{$1} = $func;
                }

                next;
            }

            next unless $current_func;

            if ( $line =~ /^\s*#\s*Args:\s*$/ ) {
                $in_args     = 1;
                $in_synopsis = 0;
                next;
            }

            if ($in_args) {
                if ( $line =~ /^\s*#\s*([^\s].*?)\s*-\s*(.*)$/ ) {
                    push @$current_args, "$1 - $2";
                    next;
                }

                if ( $line =~ /^\s*#\s*$/ ) {
                    next;
                }

                $in_args = 0;
            }

            if ( $line =~ /^\s*#\/\s*Synopsis\b/ ) {
                $in_synopsis = 1;
                $in_args     = 0;
                next;
            }

            if ($in_synopsis) {
                if ( $line =~ /^\s*#\/\s*(.*)$/ ) {
                    my $text = $1;
                    $text =~ s/^\s+//;
                    $text =~ s/\s+$//;
                    push @$current_synopsis, $text if length $text;
                    next;
                }

                $in_synopsis = 0;
            }
        }

        $flush_func->();

        if (@file_funcs) {
            my $subdir = File::Basename::dirname $file;
            $subdir =~ s!$module_dir/lib/!!;
            $funcs->{$subdir}->{$file} = \@file_funcs;
        }
    }

    foreach my $dir (keys %{$funcs}) {
        foreach my $file (keys %{$funcs->{$dir}}) {
            my @sorted_funcs = sort { $a->{name} cmp $b->{name} } @{$funcs->{$dir}{$file}};
            $funcs->{$dir}{$file} = \@sorted_funcs;
        }
    }

    $self->aliases($aliases);
    $self->hooks($hooks);
    $self->funcs($funcs);

    return;
}

sub readme_gen() {
    my $self = shift;
    my %args = @_;

    my $omodule = $self->module();
    my $aliases = $self->aliases();
    my $funcs   = $self->funcs();
    my $hooks   = $self->hooks();
    my $path    = $self->tmpl();
    my $module  = File::Basename::basename($omodule);
    my $org     = "p6m7g8-dotfiles";

    my $hier = qx/cd $omodule ; tree -I node_modules -I cdktf.out -I cdk.out -I coverage -I tsconfig.tsbuildinfo/;

    my $data = {
        aliases => $aliases,
        funcs   => $funcs,
        module  => $module,
        org     => $org,
        hier    => $hier,
        hooks   => $hooks,
    };

    my $rv = P6::Template->render(
        $data,
        %args,
        paths  => $self->tmpl_paths(),
        ifile  => $self->tmpl(),
        output => "$module/" . $self->output(),
    );

    $self->_format_markdown("$module/" . $self->output());

    return $rv;
}

sub output     { "README.md" }
sub tmpl_paths { "$ENV{PERL5LIB}/../../tt" }
sub tmpl       { "readme/readme.md.tt" }

sub _format_markdown {
    my $self   = shift;
    my $output = shift;

    my $lines = P6::IO::dread($output);
    my @out;

    for ( my $i = 0 ; $i < @$lines ; $i++ ) {
        my $line = $lines->[$i];
        my $next = $lines->[$i + 1];
        my $prev = @out ? $out[-1] : undef;
        my $prev_in = $lines->[$i - 1];

        my $is_blank   = sub { !defined $_[0] || $_[0] =~ /^\s*$/ };
        my $is_heading = $line =~ /^#{1,6}\s/;
        my $is_list    = $line =~ /^\s*-\s+/;
        my $prev_is_list = defined($prev_in) && $prev_in =~ /^\s*-\s+/;
        my $next_is_list = defined($next) && $next =~ /^\s*-\s+/;
        my $prev_is_blank = $is_blank->($prev_in);
        my $next_is_blank = $is_blank->($next);

        if ($is_heading) {
            push @out, "\n" if @out && !$prev_is_blank && !$is_blank->($prev);
            push @out, $line;
            push @out, "\n" if defined($next) && !$next_is_blank;
            next;
        }

        if ($is_list) {
            if ( defined($prev_in) && !$prev_is_list && !$prev_is_blank && !$is_blank->($prev) ) {
                push @out, "\n";
            }
            push @out, $line;
            if ( defined($next) && !$next_is_list && !$next_is_blank ) {
                push @out, "\n";
            }
            next;
        }

        push @out, $line;
    }

    my @clean;
    my $blank_run = 0;
    for my $line (@out) {
        if ( $line =~ /^\s*$/ ) {
            $blank_run++;
            next if $blank_run > 1;
        }
        else {
            $blank_run = 0;
        }
        push @clean, $line;
    }

    my $content = join "", @clean;
    P6::IO::dwrite( $output, \$content );

    return;
}

1;
