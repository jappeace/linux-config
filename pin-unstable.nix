# this allows caching of instability.
# making switches less annoying but also less up to date
import (
    builtins.fetchGit (
    {
        url = "https://github.com/NixOS/nixpkgs";
        ref = "master";
        # 21.08.2020
        rev = "7d03cf2c8d2ef8895719c4cc386ede0050f77cd0";
    }
    ))
