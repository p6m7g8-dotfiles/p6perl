package P6::CICD::Docs::Inline;
use parent 'P6::Object';

## core
use strict;
use warnings FATAL => 'all';
use Carp;

## Std

## CPAN

## Globals

## SDK
use P6::Cmd  ();
use P6::IO   ();
use P6::Util ();

## Constants

## methods

## private
sub _fields {

    {
        module => "",
        funcs  => {},
    }
}

sub _func_key_from_line {
    my $line = shift;

    return "" if $line =~ /^\s*#/;

    if ($line =~ /^\s*(?:function\s+)?((?:smile_|p6_|p6df|arkestro_)[A-Za-z0-9_:]*)\s*(?:\(\))?\s*\{/) {
        my $name = $1;
        $name .= "()" unless $name =~ /\(\)$/;
        return $name;
    }

    return "";
}

sub _extract_envs_from_line {
    my $line = shift;

    return {} if $line =~ /^\s*#/;

    my $code = $line;
    $code =~ s/\s+#.*$//;

    my %envs;
    my %skip_envs = map { $_ => 1 } qw(P6_TRUE P6_FALSE);

    while ( $code =~ /\b(?:export|unset)\s+([A-Z_][A-Z0-9_]*)/g ) {
        next if $skip_envs{$1};
        $envs{$1}++;
    }

    while ($code =~ /\bp6_env_export(?:_un)?\s+(?:--\S+\s+)?["']?([A-Z_][A-Z0-9_]*)["']?/g) {
        next if $skip_envs{$1};
        $envs{$1}++;
    }

    while ( $code =~ /\$\{?([A-Z_][A-Z0-9_]*)\}?/g ) {
        next if $skip_envs{$1};
        $envs{$1}++;
    }

    return \%envs;
}

sub _arg_from_local_line {
    my $line = shift;

    return unless $line =~ /^\s*local\b/;

    my ( $name, $rhs ) = $line =~ /^\s*local(?:\s+-[a-zA-Z]+)*\s+([a-zA-Z_][a-zA-Z0-9_]*)=(.+)$/;
    return unless $name;
    return unless $rhs =~ /\$[@*]|\$\{\d+/ || $rhs =~ /\$\d/;

    my $arg = { name => $name };

    if ( $rhs =~ /\$\{\d+:-([^}]*)\}/ ) {
        $arg->{default} = $1;
    }

    $arg->{comment} = $1 if $line =~ /# (.*)$/;
    delete $arg->{comment} unless $arg->{comment} && $arg->{comment} =~ /\w/;

    return $arg;
}

sub _arg_from_assignment_line {
    my $line = shift;

    return if $line =~ /^\s*#/;
    return if $line =~ /^\s*local\b/;

    my ( $name, $rhs ) = $line =~ /^\s*([a-zA-Z_][a-zA-Z0-9_]*)=(.+)$/;
    return unless $name;
    return unless $rhs =~ /\$[@*]|\$\{\d+/ || $rhs =~ /\$\d/;

    my $arg = { name => $name };

    if ( $rhs =~ /\$\{\d+:-([^}]*)\}/ ) {
        $arg->{default} = $1;
    }

    $arg->{comment} = $1 if $line =~ /# (.*)$/;
    delete $arg->{comment} unless $arg->{comment} && $arg->{comment} =~ /\w/;

    return $arg;
}

sub _post_init {
    my $self = shift;
    my %args = @_;

    $self->parse();
    $self->doc_gen();
    $self->splice_in();

    return;
}

sub doc_gen_func {
    my $func = shift;

    my $rvs = $func->{rvs};
    my $rv  = $rvs->[0];

    my $args = $func->{args};

    my $str = "# Function: ";

    if ( $rv && $rv->{type} ne "void" ) {
        no warnings qw(uninitialized);
        $str .= "$rv->{type} $rv->{name} = ";
    }

    $str .= "$func->{name}";

    $str .= "(";
    foreach my $arg (@$args) {
        $str .= "[" if exists $arg->{default};
        $str .= "$arg->{name}";
        $str .= "=$arg->{default}" if exists $arg->{default};
        $str .= "]"                if exists $arg->{default};
        $str .= ", ";
    }
    $str =~ s/, $/)/;
    $str .= ")" unless $str =~ /\)$/;

    $str .= "\n#\n";

    $str;
}

sub doc_gen_args {
    my $args = shift;

    my $str = "#  Args:\n";

    foreach my $arg (@$args) {
        no warnings qw(uninitialized);
        $str .= "#\t";
        $str .= "OPTIONAL " if exists $arg->{default};
        $str .= "$arg->{name} -";
        $str .= " $arg->{comment}"   if exists $arg->{comment};
        $str .= " [$arg->{default}]" if exists $arg->{default};
        $str .= "\n";
    }
    $str .= "#\n";

    $str;
}

sub doc_gen_returns {
    my $rvs = shift;

    my @non_voids = grep { $_->{type} ne "void" } @$rvs;
    return unless @non_voids;

    my $str = "#  Returns:\n";

    foreach my $rv (@$rvs) {
        no warnings qw(uninitialized);
        next if $rv->{type} eq "void";
        $str .= "#\t$rv->{type} - $rv->{name}";
        if ( $rv->{comment} ) {
            $str .= ": $rv->{comment}\n";
        }
        else {
            $str .= "\n";
        }
    }
    $str .= "\n" unless $str =~ /\n$/;
    $str .= "#\n";

    $str;
}

sub doc_gen_depends {
    my $depends = shift;

    my $deps = "";
    foreach my $depend ( sort keys %$depends ) {
        $deps .= "$depend ";
    }
    $deps =~ s/ $//;
    my $str = "#  Depends:\t $deps\n";

    $str;
}

sub doc_gen_envs {
    my $envs = shift;

    my $environment = "";
    foreach my $env ( sort keys %$envs ) {
        $environment .= "$env ";
    }
    $environment =~ s/ $//;
    my $str = "#  Environment:\t $environment\n";

    $str;
}

sub doc_gen() {
    my $self = shift;
    my %args = @_;

    my $module = $self->module();

    my $funcs = $self->funcs();
    foreach my $fname ( sort keys %{ $self->funcs() } ) {
        my $func = $funcs->{$fname};

        ## build
        my @doc_lines = ();
        push @doc_lines, "#<";
        push @doc_lines, "#";

        push @doc_lines, doc_gen_func($func);
        push @doc_lines, doc_gen_args( $func->{args} )   if $func->{args};
        push @doc_lines, doc_gen_returns( $func->{rvs} ) if $func->{rvs};

#        push @doc_lines, doc_gen_depends( $func->{depends} ) if $func->{depends};
        push @doc_lines, doc_gen_envs( $func->{envs} ) if $func->{envs};

        push @doc_lines, "#>";

        $func->{doc_lines} = \@doc_lines;
    }

    $self->funcs($funcs);

    return;
}

sub splice_in() {
    my $self = shift;
    my %args = @_;

    my $files = $self->files();
    my $mark  = "#" x 70;

    my $funcs = $self->funcs();

    foreach my $file ( sort @$files ) {
        P6::Util::debug("splice: $file\n");
        my $doc_in    = 0;
        my $func      = "";
        my @new_lines = ();

        my @lines = grep { chomp; 1 } @{ P6::IO::dread($file) };
        foreach my $line (@lines) {
            P6::Util::debug("LINE: $line\n");
            next if $line =~ /^$mark/;
            $doc_in = 1, next if $line =~ /^#</;
            $doc_in = 0, next if $line =~ /^#>/;
            next if $doc_in;
            next if $line =~ /^#\//;

            my $fname = _func_key_from_line($line);
            if ($fname) {

                P6::Util::debug("DEF: $fname\n");

                $func = $funcs->{$fname};
                if ($func) {
                    push @new_lines, $mark;
                    push @new_lines, grep { chomp; 1 } @{ $func->{doc_lines} };
                    push @new_lines, grep { chomp; 1 }
                      @{ $func->{extra_docs} };
                    push @new_lines, $mark;
                }
            }

            push @new_lines, $line;
        }

        my $content = join "\n", @new_lines;
        $content .= "\n";
        P6::IO::dwrite( $file, \$content );
    }

    return;
}

sub files() {
    my $self = shift;

    my $module_dir = $self->module();
    my $lib_dir    = "$module_dir/lib";
    my $bin_dir    = "$module_dir/bin";

    P6::Util::debug("lib_dir: $lib_dir\n");
    P6::Util::debug("bin_dir: $bin_dir\n");

    my $libs =
      -d $lib_dir
      ? P6::IO::scan( $lib_dir, qr/[a-zA-Z0-9]/, files_only => 1 )
      : [];
    my $bins =
      -d $bin_dir
      ? P6::IO::scan( $bin_dir, qr/[a-zA-Z0-9]/, files_only => 1 )
      : [];

    my $files = [ @$libs, @$bins ];

    push @$files, "$module_dir/init.zsh" if -e "$module_dir/init.zsh";
    push @$files, "$module_dir/.zsh-me"  if -e "$module_dir/.zsh-me";

    P6::Util::debug_dumper( "FILES", $files );

    $files;
}

sub parse {
    my $self = shift;

    my @types = (qw(array bool code false filter float int ipv4 jmesp path size_t stream url words str true void aws_arn aws_account_id aws_resource_id aws_logical_id));
    push @types, (qw(obj hash list string scalar item item_ref obj_ref));
    my $types_re = join '|', @types;

    P6::Util::debug("types_re=[$types_re]\n");

    my $files = $self->files();

    my $funcs      = {};
    my $extra_docs = [];
    foreach my $file ( sort @$files ) {
        P6::Util::debug("FILE: $file\n");
        my $func    = "";
        my $in_func = 1;
        my $arg_end = 0;
        my $arg_started = 0;
        my %args_seen;

        my $lines = P6::IO::dread($file);
        foreach my $line (@$lines) {
            if ( $line =~ /^#\// ) {
                push @$extra_docs, $line;
            }

            my $func_key = _func_key_from_line($line);
            if ($func_key) {
                $in_func = 1;

                $func = $func_key;
                $arg_end = 0;
                $arg_started = 0;
                %args_seen = ();

                my $name = $func;
                $name =~ s/\(\)$//;

                P6::Util::debug("\tFUNC: $name\n");

                $funcs->{$func}->{name}       = $name;
                $funcs->{$func}->{file}       = $file;
                $funcs->{$func}->{extra_docs} = $extra_docs;
                $extra_docs                   = [];
            }

            if ( $in_func && $line =~ /^\s*$/ ) {
                $arg_end = 1 if $arg_started;
            }

            if ( !$arg_end ) {
                my $arg = _arg_from_local_line($line);
                $arg ||= _arg_from_assignment_line($line);
                if ( $arg && !$args_seen{ $arg->{name} } ) {
                    P6::Util::debug_dumper( "arg", $arg );
                    push @{ $funcs->{$func}->{args} }, $arg;
                    $args_seen{ $arg->{name} } = 1;
                    $arg_started = 1;
                }
            }

            if ( !$arg_end && $line =~ /^\s*shift(?:\s+(\d+))?/ ) {
                my $comment;
                $comment = $1 if $line =~ /# (.*)$/;
                my $arg = {
                    name    => "...",
                    comment => $comment,
                };
                if ( !$args_seen{ $arg->{name} } ) {
                    push @{ $funcs->{$func}->{args} }, $arg;
                    $args_seen{ $arg->{name} } = 1;
                    $arg_started = 1;
                }
            }

            my $envs = _extract_envs_from_line($line);
            foreach my $env ( sort keys %$envs ) {
                P6::Util::debug("env: [$env]\n");
                $funcs->{$func}->{envs}->{$env}++;
            }

            if ( $line =~ /\s(p6_[a-zA-Z0-9]+)/ ) {
                my $depends = $1;
                my $m       = $depends;
                $m =~ s/p6_//;
                if ($depends !~ /return|debug/ && $self->module() !~ /$m/) {
                    P6::Util::debug("depends: [$depends]\n");
                    $funcs->{$func}->{depends}->{$depends}++;
                }
            }

            my $rv = {};
            if ( $line !~ /^\s*#/ && $line =~ /\bp6_return_($types_re)\b/ ) {
                $rv->{type} = $1;

                P6::Util::debug("\treturn: $line");

                if ( $line =~ /\"([^\"]+)\"/ ) {
                    $rv->{name} = $1;
                }
                elsif ( $line =~ /'([^']+)'/ ) {
                    $rv->{name} = $1;
                }
                elsif ( $line =~ /\bp6_return_(?:$types_re)\s+\$?([A-Za-z_][A-Za-z0-9_]*)/ ) {
                    $rv->{name} = $1;
                }
            }

            if ( $rv->{type} ) {
                $rv->{name} = "" unless $rv->{name};
                $rv->{name} =~ s/^\$//;

                $rv->{comment} = $1 if $line =~ /# (.*)$/;

                P6::Util::debug_dumper( "rv", $rv );
                push @{ $funcs->{$func}->{rvs} }, $rv;
            }

            if ( $line =~ /^\s*}$/ ) {
                $in_func = 0;
                $arg_end = 0;
            }
        }
    }

    delete $funcs->{""};

    $self->funcs($funcs);

    return;
}

1;
