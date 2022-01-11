# this allows caching of instability.
# making switches less annoying but also less up to date
let agda-nix = builtins.fetchGit (
    {
        url = "https://github.com/jappeace/agda-nix";
        ref = "master";
        # 2022.01.02
        rev = "5b10b95a4a615a0438de094bcbe58de03bffe480";
    }
    );
in
{
  agda-mode = import "${agda-nix}/nix/agda-mode.nix" {};
  agsy = (import "${agda-nix}/nix/pin.nix").agsy;
}
