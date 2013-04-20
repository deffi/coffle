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

This is the typical way to use coffle with configuration files from a repository (using bash):
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
