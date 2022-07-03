# this allows caching of instability.
# making switches less annoying but also less up to date
let agda-nix = builtins.fetchGit (
    {
        url = "https://github.com/jappeace/agda-nix";
        ref = "master";
        # 2022.07.03
        rev = "b58f8ee92c6ae667fc08a052e2e301e5809c5b44";
    }
    );
in
{
  agda-mode = import "${agda-nix}/nix/agda-mode.nix" {};
  agsy = (import "${agda-nix}/nix/pin.nix").agsy;
}
