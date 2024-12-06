{
  description = "Zlib compiled with Zig";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    systems.url = "github:nix-systems/default-linux";
    flake-utils.url = "github:numtide/flake-utils";
    zig = {
      url = "github:ziglang/zig?ref=pull/20511/head";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
      flake-utils,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;

      defaultOverlay =
        pkgs: prev: with pkgs; {
          zig =
            (prev.zig.overrideAttrs (
              finalAttrs: p: {
                version = "0.14.0-git+${inputs.zig.shortRev or "dirty"}";
                src = inputs.zig;

                doInstallCheck = false;

                postBuild = "";
                postInstall = "";

                outputs = [ "out" ];
              }
            )).override
              {
                llvmPackages = llvmPackages_19;
              };

          zlib-zig = stdenv.mkDerivation {
            pname = "zlib-zig";
            version = self.shortRev or "dirty";

            src = lib.cleanSource self;

            nativeBuildInputs = [
              pkgs.zig
            ];
          };
        };
    in
    flake-utils.lib.eachSystem (import systems) (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system}.appendOverlays [
          defaultOverlay
        ];
      in
      {
        packages = {
          default = pkgs.zlib-zig;
        };

        devShells = {
          default = pkgs.zlib-zig;
        };

        legacyPackages = pkgs;
      }
    )
    // {
      overlays = {
        default = defaultOverlay;
        dart-zig = defaultOverlay;
      };
    };
}
