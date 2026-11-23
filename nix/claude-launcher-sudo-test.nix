# Boots a VM with the launcher sudo module and runs the vibes launcher's sudo
# calls as a wheel user, by bare command name through the login PATH as
# claude.sh does. sudo -n refuses instead of prompting, so a rule that fails
# to match shows up as "a password is required". Rendering the sudoers file
# or running visudo -c cannot catch this: both passed while every launch
# still prompted.
{ pkgs ? import (import ../npins).nixpkgs { } }:
pkgs.testers.runNixOSTest {
  name = "claude-launcher-sudo";

  nodes.machine = {
    imports = [ ./claude-launcher-sudo.nix ];
    users.users.jappie = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      password = "only-for-the-test-vm";
    };
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    password_prompt = "a password is required"

    def sudo_as_jappie(command):
        return machine.execute(f"su - jappie -c 'sudo -n {command}' 2>&1")[1]

    for command in [
        "systemd-nspawn --version",
        "systemctl reset-failed machine-cabal.scope",
        "systemctl stop machine-cabal.scope",
        "machinectl terminate cabal",
    ]:
        output = sudo_as_jappie(command)
        assert password_prompt not in output, f"'sudo {command}' asked for a password:\n{output}"

    for command in [
        "systemctl stop nix-daemon.service",
        "machinectl shell cabal",
    ]:
        output = sudo_as_jappie(command)
        assert password_prompt in output, f"'sudo {command}' ran without a password:\n{output}"
  '';
}
