set -xe

cd /linux-config/

nixpkgs=$(nix-instantiate --eval -E "let sources = import ./npins; in sources.nixpkgs.outPath" | jq -r .)
sudo nixos-rebuild "$1" \
                -I nixpkgs=${nixpkgs} \
                -I nixos-config=/etc/nixos/configuration.nix \
                --fast

