
######################################################################
#<
#
# Function: p6df::modules::p6perl::deps()
#
#>
######################################################################
p6df::modules::p6perl::deps() {
    ModuleDeps=(
      p6m7g8-dotfiles/p6common
    )
}

######################################################################
#<
#
# Function: p6df::modules::p6perl::init()
#
#>
######################################################################
p6df::modules::p6perl::init() {

    p6_perl_init $P6_DFZ_SRC_P6M7G8_DOTFILES_DIR/p6perl
}

######################################################################
#<
#
# Function: p6_perl_init(dir)
#
#  Args:
#	dir -
#
#>
######################################################################
p6_perl_init() {
    local dir="$1"

    p6_path_if "$dir/bin"
    export PERL5LIB=$dir/lib/perl5
}
