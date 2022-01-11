# this allows caching of instability.
# making switches less annoying but also less up to date
import (
    builtins.fetchGit (
    {
        url = "https://github.com/NixOS/nixpkgs";
        ref = "master";
        # 2022.01.09
        rev = "df6bc254d20eac663fed46d042223990ac64a826";
    }
    ))
