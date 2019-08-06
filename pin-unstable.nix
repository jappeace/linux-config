# this allows caching of instability.
# making switches less annoying but also less up to date
import (
    builtins.fetchGit (
    {
        url = "https://github.com/NixOS/nixpkgs";
        ref = "master";
        rev = "19180dfd5b6fcd50d84922438c7bf646e0fcb4ac";
    }
    ))
