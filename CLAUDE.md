# linux-config

## Tests
This repository doesn't need tests. Don't add one for a new script,
keybinding, service or module, even where a global rule asks for a test of
new behaviour; this rule takes precedence here (Jappie, 27 nov 2026).

Existing tests in `default.nix` and `nix/ci.nix` stay unless Jappie asks to
remove them, and `nix-build nix/ci.nix` still runs before finishing a task.
