
######################################################################
#<
#
# Function: p6df::modules::p6perl::deps()
#
#>
######################################################################
p6df::modules::p6perl::deps() {
    ModuleDeps=(
      p6m7g8/p6common
    )
}

######################################################################
#<
#
# Function: p6df::modules::p6perl::external::brew()
#
#>
######################################################################
p6df::modules::p6perl::external::brew() { }

######################################################################
#<
#
# Function: p6df::modules::p6perl::init()
#
#>
######################################################################
p6df::modules::p6perl::init() {

    p6_perl_init $P6_DFZ_SRC_DIR/p6m7g8/p6perl
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

    p6df::util::path_if "$dir/bin"
    export PERL5LIB=$dir/lib/perl5
}