Coffle
======

Introduction
------------

Coffle allows you to keep user configuration files (dotfiles) for multiple hosts or
user accounts in a common location (such as an SVN or git repository) and still
be able to maintain differences between different hosts or user accounts.

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
```

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


User guide
----------

All configuration file templates managed by coffle are placed beneath one directory, the
*coffle repository*. All commands shown in this section must be executed in the
coffle repository.

The files are *built* by processing the templates from the coffle repository
and writing the results to a subdirectory of the coffle repository. The files
are *installed* by placing a symbolic link to the build result in the target
directory, which is the user's home directory.


### The coffle repository

To use a directory as a coffle repository, it must be initialized:
```bash
coffle init
```

Each file or directory in the repository corresponds to one file or directory in the
target directory. The names of files and directories are processed as follows:

* a file name not starting with an underscore or a hypen is not modified
* an underscore at the beginning of a file name is converted into a period
  (e. g. `_bashrc` in the repository becomes `.bashrc` in the target directory)
* a hyphen at the beginning of a file name is simply removed (e. g. `-_foo`
  in the repository becomes `_foo` in the target directory).

The directory structure of the repository is replicated in the target directory. For
example, `_ssh/authorized_keys` in the repository becomes `.ssh/authorized_keys` in the
target directory.

Hidden files and directories (i. e. files and directories starting with a period) in the
repository are used internally by coffle and are not treated as templates.


### Configuration file templates

Configuration files are processed using ERB. This means that typically, the
contents of the template files are simply copied to the target file. Some
additional functionality can be included by using ERB tags.


#### Comments

Comments may be included by using ERB comment delimiters:
```erb
...
<%# This is a comment %>
...
```

Comments will not show up in the generated files.


#### Host-specific output

To generate host-specific output, the `host` and `not_host` commands can be
used:
```erb
<%- host("magrathea", "damogran", /websrv[123]/) { -%>
alias ls='ls --color=auto'
<%- } -%>
```

The portion of the template enclosed in the block will only be processed if the
host name matches any of the specified strings (in quotes) or regular
expressions (in slashes).

Similarly, the `not_host` command can be used to specify a portion of the
template that is processed if the host does *not* match any of a list of
strings or regular expressions: 
```erb
<%- not_host("magrathea", "damogran", /websrv[123]/) { -%>
alias ls='ls --color=never'
<%- } -%>
```


#### Skipping files

A file can be *skipped*. Skipping a file indicates that it is not under coffle
control. This is useful in conbination with host-specific processing to place a
file under coffle control on some hosts and leave it alone on other hosts.

A file is skipped using the `skip!` command:
```erb
<%- not_host("magrathea", "damogran") { skip! } -%> 
```

Files can also be skipped unconditionally:
```erb
<%- skip! -%>
```

A skipped file will be trated as if it didn't exist. It is not installed by
`coffle install`. If the file was installed before, it will be uninstalled when
the file is rebuilt (note, however, that it will not be reinstalled
automatically on build when it is no longer skipped).


#### Message about auto-created files

The `automessage` command inserts a message stating that the target file has
been automatically created, along with some additional information:
```erb
<%= automessage %>
```

The generated message looks like this:
```
# This file was autogenerated from /home/martin/src/config/_bashrc by
# martin@damogran on 2013-03-10 12:11:37 -0700. You should not make any changes
# here, as they may be overwritten when the file is regenerated.
# 
# To regenerate this file, execute the following command:
#     /home/martin/bin/coffle build
# in the following directory:
#     /home/martin/src/config
```

By default, `# ` is used to introduce a comment. This can be changed; for
example, for a VIM configuration file (`.vimrc`, or `_vimrc` in the
repository), a single quote should be used:
```
<%= automessage '" ' %>
```

#### OpenSSH specific functionality

This functionality makes it easier to specify an `authorized_keys` file for
OpenSSH. Again, this is particularly useful in combination with host-specific
output.

To use the OpenSSH functionality, include the following command in the
template:
```erb
<%- include Ssh -%>
```

SSH keys can be defined using the `define_keys` command:
```erb
<%- define_keys { -%>
ssh-dss AAAAB3Nz[...]kUmH/S== martin@magrathea
ssh-dss AAAAB3Nz[...]8sMmHg== martin@damogran
ssh-dss AAAAB3Nz[...]OKRmAe1= apache@websrv
ssh-dss AAAAB3Nz[...]HYMxHb7= mongrel@websrv
<%- } -%> 
```

SSH keys can the be added using the `key` command:
```erb
<%# This key is always allowed %>
<%= key "martin@magrathea" %>

<%# These keys are only allowed on specific hosts %>
<%- host(/websrv[123]/) { -%>
<%= key "martin@damogran" %>
<%= key "apache@websrv", "mongrel@websrv" %>
<%- } -%>

<%# To avoid giving unintentional access to other hosts, skip the file on all
hosts except those listed here %>
<%- not_host("magrathea", "damogran", /websrv[123]/) { skip! } -%>
```


### Installing the configuration files

To install the configuration files, use the following command:
```bash
coffle install
```

This will build all files (except skipped files) and install them.

Files that already exist in the target directory will not be overwritten,
unless the ``--overwrite`` option is specified:
```bash
coffle install --overwrite
```

In this case, a backup of the original file will be made in a subdirectory of
the coffle repository.


### Updating the configuration files

When the configuration file templates change, the files must be rebuilt:
```bash
coffle build
```

There is no need to install the files again, as the target directory
contains symbolic links to the build results.


### Getting information about the repository

```coffle info``` prints the locations of the various directories used.
```coffle status``` prints, for each repository entry, the entry type (file or
directory), the build status and the installation status.


### Showing differences

In case an installed (auto-generated) file has been manually modified,
```coffle diff``` shows the difference between the automatically generated and
the manually modified file as a unified diff. This may or may not be helpful in
merging the modifications into the template.

This functionality relies on the `diff` program.


### Uninstalling the configuration files

```coffle uninstall``` can be used to restore the target directory to the state
before running coffle. All installed files are removed and the backups restored
if a file had been overwritten by the install operation.

Note that directories created by coffle may not be removed by the uninstall
operation.

