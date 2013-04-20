Coffle
======

Introduction
------------

Coffle is a configuration file preprocessor. It allows you to keep configuration
files for multiple hosts or user accounts in a common location (such as a repository)
and still be able to maintain differences between different hosts or user accounts.

This is achieved by generating the configuration files from templates (using Ruby's
ERB).


Usage
-----

This is the typical way to use coffle with configuration files from a repository in
bash (assuming that ~/bin exists and is part of $PATH):

```bash
# Checkout and install coffle
git clone git://github.com/deffi/coffle coffle
ln -s `pwd`/coffle/script/coffle.rb ~/bin/coffle
 
# Checkout and install the configuration
git clone [your configuration files repository] config
cd config
coffle install --overwrite
````

