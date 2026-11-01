# hex-flake

Nix flake for [Hex](https://github.com/anomalyco/hex) on Apple silicon macOS.

Upstream's flake only covers `x86_64-linux`, so use it directly on Linux. This
flake repackages the signed macOS release zip without modifying it.

## Usage

```nix
{
  inputs.hex = {
    url = "github:winter-08/hex-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

Then import the nix-darwin module and enable it:

```nix
{
  imports = [ inputs.hex.darwinModules.hex ];

  programs.hex = {
    enable = true;
    autostart = true;
    settings.dictation_hotkey = "option+space";
  };
}
```

The module installs the app and CLI and sets `DisableUpdates`, because Hex can't
replace itself in the read-only store. It needs `system.primaryUser` set. Launch
Hex once to grant Microphone and Accessibility access and download a model.

`settings` matches upstream's Home Manager option: activation runs
`hex settings apply` with the keys `hex settings list` prints. Declared keys
overwrite Hex's values, and anything undeclared keeps its value from the app.

## Permissions

macOS ties these grants to the app's code signature, not its path:

```
identifier "anomaly.hex" and anchor apple generic
  and certificate leaf[subject.OU] = "5NZ4Q7NXJ4" (plus the Developer ID markers)
```

The derivation skips fixup so the bundle stays byte-identical, and CI fails if
the built app stops satisfying that identity.

## Updating

A daily workflow pins the newest stable `vX.Y.Z` release, then builds it and
verifies the signature on macOS before pushing. To do it by hand:

```sh
nix run .#update
nix build .#hex
bash scripts/verify-signature.sh result/Applications/Hex.app
```
