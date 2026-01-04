set -xe

nixpkgs=$(nix-instantiate --eval -E "let sources = import ./npins; in sources.nixpkgs.outPath" | jq -r .)
nixos-rebuild "$1" \
                -I nixpkgs=${nixpkgs} \
                -I nixos-config=/etc/nixos/configuration.nix \
                --fast
