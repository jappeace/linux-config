# this allows caching of instability.
# making switches less annoying but also less up to date
import (
    builtins.fetchGit (
    {
        url = "https://github.com/NixOS/nixpkgs";
        ref = "master";
        rev = "c8c30fac9b37e6f173d14cbf8e245bf6a856b0fd";
    }
    ))
