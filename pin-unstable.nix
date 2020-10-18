# this allows caching of instability.
# making switches less annoying but also less up to date
import (
    builtins.fetchGit (
    {
        url = "https://github.com/NixOS/nixpkgs";
        ref = "master";
        # 18.10.2020
        rev = "1f378561c623cc0d36dc3c8c235cbb5476ad1868";
    }
    ))
