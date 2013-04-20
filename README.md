Coffle
======

Introduction
------------

Coffle allows you to keep user configuration files (dotfiles) for multiple hosts or
user accounts in a common location (such as a repository) and still be able to maintain
differences between different hosts or user accounts.

This is achieved by generating the configuration files from templates (using Ruby's
ERB).


Overview
--------

This is the typical way to use coffle with configuration files from a repository (using
bash, and assuming that coffle is installed):
```bash
git clone [your configuration files repository] config
cd config
coffle install --overwrite
````

When any of the templates is changed, update the configuration files:
```bash
cd config
coffle build
```

To install coffle from github (this example assumes that ~/bin exists and is part of $PATH):
```bash
git clone https://github.com/deffi/coffle.git coffle
ln -s `pwd`/coffle/script/coffle.rb ~/bin/coffle
```


Usage
-----

All configuration file templates managed by coffle are placed beneath one directory, the
*coffle repository* (also called *source directory*; note that this has nothing to do with
the directory where the coffle source code is located). All commands shown in this section
must be executed in the source directory.

The configuration file templates from the coffle repository are processed and written to
the *target directory*, which is the user's home directory.


### Creating a coffle repository

To use a directory as a source directory, it must be initialized:
```bash
coffle init
```

Each file or directory in the repository corresponds to one file or directory in the
target directory. The names of files and directories are processed as follows:

* a file name not starting with an underscore or a hypen are not modified
* an underscore at the beginning of a file name is converted into a period
  (e. g. `_bashrc` in the repository becomes `.bashrc` in the target directory)
* a hyphen at the beginning of a file name is simply removed (e. g. `-_foo`
  in the repository becomes `_foo` in the target directory).

The directory structure of the repository is replicated in the target directory. For
example, `_ssh/authorized_keys` in the repository becomes `.ssh/authorized_keys` in the
target directory.

Hidden files and directories (i. e. files and directories starting with a period) in the
repository are used internally by coffle and are not treated as templates.





### Installing the configuration files

### Updating the configuration files

### Uninstalling the configuration files

### Templates






