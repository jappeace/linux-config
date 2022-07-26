# this allows caching of instability.
# making switches less annoying but also less up to date
let agda-nix = builtins.fetchGit (
    {
        url = "https://github.com/jappeace/agda-nix";
        ref = "master";
        # 2022.07.03
        rev = "43c6b38605755b222dc9d48b6c92dbb6912b7a1f";
    }
    );
in
{
  agda-mode = import "${agda-nix}/nix/agda-mode.nix" {};
  agsy = (import "${agda-nix}/nix/pin.nix").agsy;
}
