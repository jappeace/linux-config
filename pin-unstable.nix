# this allows caching of instability.
# making switches less annoying but also less up to date
import (
    builtins.fetchGit (
    {
        url = "https://github.com/NixOS/nixpkgs";
        ref = "master";
        rev = "3541e8b4fbf01731580b2f26a3de41200213e6f1";
    }
    ))
