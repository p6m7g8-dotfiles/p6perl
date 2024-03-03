# shellcheck shell=bash
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
#  Environment:	 P6_DFZ_SRC_P6M7G8_DOTFILES_DIR
#>
######################################################################
p6df::modules::p6perl::init() {

  p6_perl_init $P6_DFZ_SRC_P6M7G8_DOTFILES_DIR/p6perl

  p6_return_void
}

######################################################################
#<
#
# Function: p6_perl_init(dir)
#
#  Args:
#	dir -
#
#  Environment:	 PERL5LIB
#>
######################################################################
p6_perl_init() {
  local dir="$1"

  p6_path_if "$dir/bin"
  p6_env_export PERL5LIB "$dir/lib/perl5"

  p6_return_void
}
