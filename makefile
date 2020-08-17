die-emacs:
    sudo nixos-rebuild switch && systemctl daemon-reload --user && systemctl restart emacs --user
