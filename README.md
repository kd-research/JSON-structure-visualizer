# Intro {#sec:intro}

Based on https://github.com/bobvanderlinden/templates/blob/master/ruby/flake.nix

This project have ruby development environment managed by nix.

To run and ruby code, use:

```
nix-shell --command "ruby main.rb"
```

`nix build` works only if you execute first the following steps
```
nix-shell
bundle install
bundix -m
```
