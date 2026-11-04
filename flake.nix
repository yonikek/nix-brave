{
  description = "Standalone Nix package for Brave Browser and Brave Origin";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      overlays.default = final: prev:
        let
          bravePackages = import ./pkgs/brave {
            callPackage = prev.callPackage;
          };
        in
        {
          inherit (bravePackages) brave brave-origin;
        };

      nixosModules = {
        bravePolicies = import ./modules/brave-policies.nix;
      };

      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
        in
        {
          default = pkgs.brave;
          brave = pkgs.brave;
          brave-origin = pkgs.brave-origin;
        }
      );
    };
}
