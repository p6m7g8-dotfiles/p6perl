# P6's POSIX.2: p6perl

## Table of Contents

- [Badges](#badges)
- [Summary](#summary)
- [Contributing](#contributing)
- [Code of Conduct](#code-of-conduct)
- [Usage](#usage)
  - [Hooks](#hooks)
  - [Functions](#functions)
- [Hierarchy](#hierarchy)
- [Author](#author)

## Badges

[![License](https://img.shields.io/badge/License-Apache%202.0-yellowgreen.svg)](https://opensource.org/licenses/Apache-2.0)

## Summary

TODO: Add a short summary of this module.

## Contributing

- [How to Contribute](<https://github.com/p6m7g8-dotfiles/.github/blob/main/CONTRIBUTING.md>)

## Code of Conduct

- [Code of Conduct](<https://github.com/p6m7g8-dotfiles/.github/blob/main/CODE_OF_CONDUCT.md>)

## Usage

### Hooks

- `deps` -> `p6df::modules::p6perl::deps()`
- `init` -> `p6df::modules::p6perl::init(_module, dir)`

### Functions

#### p6perl

##### p6perl/init.zsh

- `p6_perl_init(dir)`
  - Args:
    - dir - 
- `p6df::modules::p6perl::deps()`
- `p6df::modules::p6perl::init(_module, dir)`
  - Args:
    - _module - 
    - dir - 

## Hierarchy

```text
.
├── bin
│   ├── doc_inline.pl
│   ├── doc_readme.pl
│   ├── elb_listener_show.pl
│   ├── gen.pl
│   └── sg_show.pl
├── init.zsh
├── lib
│   └── perl5
│       ├── P6
│       │   ├── AWS
│       │   │   ├── EC2
│       │   │   │   └── VPC
│       │   │   │       └── SG.pm
│       │   │   ├── ELB.pm
│       │   │   ├── SGen
│       │   │   │   ├── Cmd.pm
│       │   │   │   └── Service.pm
│       │   │   └── SGen.pm
│       │   ├── Cache.pm
│       │   ├── CICD
│       │   │   └── Docs
│       │   │       ├── Inline.pm
│       │   │       └── Readme.pm
│       │   ├── CLI.pm
│       │   ├── Cmd.pm
│       │   ├── Const.pm
│       │   ├── DB.pm
│       │   ├── DT.pm
│       │   ├── Email.pm
│       │   ├── IO.pm
│       │   ├── MVC
│       │   │   ├── C
│       │   │   │   └── Router.pm
│       │   │   ├── C.pm
│       │   │   ├── M.pm
│       │   │   ├── Util
│       │   │   │   └── DB.pm
│       │   │   └── V.pm
│       │   ├── Object.pm
│       │   ├── Template.pm
│       │   └── Util.pm
│       └── P6.pm
├── README.md
└── tt
    ├── aws_func.tt
    ├── aws_uw_func.tt
    └── readme
        └── readme.md.tt

16 directories, 34 files
```

## Author

Philip M. Gollucci <pgollucci@p6m7g8.com>
