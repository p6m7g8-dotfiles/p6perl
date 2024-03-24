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
# Function: p6df::modules::p6perl::init(_module, dir)
#
#  Args:
#	_module -
#	dir -
#
#>
######################################################################
p6df::modules::p6perl::init() {
  local _module="$1"
  local dir="$2"

  p6_perl_init "$dir"

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
