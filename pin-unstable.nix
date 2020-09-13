# this allows caching of instability.
# making switches less annoying but also less up to date
import (
    builtins.fetchGit (
    {
        url = "https://github.com/NixOS/nixpkgs";
        ref = "master";
        # 12.09.20202
        rev = "0527aaa44708c0a56417868e4db881b5d4fffb74";
    }
    ))
