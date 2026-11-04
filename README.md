# nix-brave

A small standalone Nix flake packaging the upstream Brave Browser and Brave Origin binaries, based on the Nixpkgs packaging at:

<https://github.com/NixOS/nixpkgs/tree/nixos-unstable/pkgs/applications/networking/browsers/brave>

The package expressions in `pkgs/brave/` are copied from the Nixpkgs package directory. The initial snapshot in this archive is Brave **1.98.63** (both Browser and Origin), with the upstream hashes from that package snapshot. The updater and CI are included so you can take ownership of subsequent updates.

## Supported systems

The upstream package metadata currently includes:

- `x86_64-linux`
- `aarch64-linux`
- `aarch64-darwin`

The flake exports these systems. This does not imply that every platform has been built or runtime-tested by this standalone repository; the included GitHub Actions workflow builds on `x86_64-linux`.

## Build

```sh
nix build .#brave
nix build .#brave-origin
```

The default package is Brave Browser:

```sh
nix build
```

The first invocation will create `flake.lock`, pinning the Nixpkgs input. Commit that file to your own repository to make future evaluations reproducible.

## Use as an overlay

Add this repository as a flake input:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    brave.url = "github:YOUR_USERNAME/nix-brave";
    brave.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, ... }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ({ pkgs, ... }: {
          nixpkgs.overlays = [ inputs.brave.overlays.default ];
          environment.systemPackages = [ pkgs.brave ];
        })
      ];
    };
  };
}
```

The overlay exposes both `pkgs.brave` and `pkgs.brave-origin`.

## Updating Brave

Run:

```sh
python3 ./pkgs/brave/update.py
```

The script reads Brave's release version metadata and per-archive `.sha256` files from `versions.brave.com` and rewrites:

- `pkgs/brave/packages/brave.nix`
- `pkgs/brave/packages/brave-origin.nix`

Review the resulting changes, read the corresponding upstream release notes, then build and test before merging:

```sh
nix flake check
nix build .#brave .#brave-origin --no-link
```

A scheduled GitHub Actions workflow runs the updater daily and opens a pull request when metadata changes. The CI workflow evaluates the flake and builds both packages on x86_64 Linux. Review the PR rather than automatically deploying browser updates: browsers are security-sensitive software.

## Binary cache

No cache is configured by default. For multiple machines, you can publish successful CI builds to a cache such as Cachix or a self-hosted Attic instance. Configure the cache's signing key and CI secrets separately; do not commit private signing keys to this repository.

## Nixpkgs integrations

This repository packages the browser derivations and exports an overlay. It does **not** restore NixOS module integrations removed alongside Brave from Nixpkgs (for example, the Brave-specific policy and browserpass paths). If you rely on those features, maintain corresponding module changes in your NixOS configuration or a separate module repository.

## Maintenance notes

- Keep the Nixpkgs input pinned with `flake.lock`; update it intentionally and test after doing so.
- Check the browser's upstream release notes and security advisories when reviewing version bumps.
- Test launch, audio, GPU acceleration, Wayland/X11 integration and profile behaviour on the desktop environments you use. A successful derivation build is not a complete runtime test.
- Keep package platform metadata aligned with the architectures for which upstream publishes binaries.

## Attribution and licensing

The Nix packaging expressions were copied from the Nixpkgs Brave package directory and retain the upstream package metadata. Nixpkgs is MIT-licensed; the Brave browser binaries are distributed by Brave under their own applicable terms. See <https://github.com/NixOS/nixpkgs/blob/master/COPYING> and <https://brave.com/terms-of-use/>. This repository does not redistribute Brave binaries; Nix fetches them from Brave's published release URLs.
