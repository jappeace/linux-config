# Forces wayland, also enables touch support.
# Shared between environment.nix (system packages) and email.nix
# (the home-manager thunderbird package).
pkgs: pkg:
pkgs.symlinkJoin {
  name = "${pkg.pname or "app"}-tablet-safe";
  paths = [ pkg ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    # We find the main binary and wrap it with our safety flags
    wrapProgram $out/bin/${pkg.pname or (builtins.parseDrvName pkg.name).name} \
      --set MOZ_USE_XINPUT2 "1" \
      --set MOZ_ENABLE_WAYLAND "1"
  '';
}
