{
  description = "Simple Haskell Shell for GHCs (9.x so far)";

  inputs.nixpkgs.url = "nixpkgs/release-24.05";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  nixConfig = {
    bash-prompt-prefix = "haskell > ";
  };

  outputs = { self, nixpkgs, flake-utils }: 
    let
      systems = flake-utils.lib.defaultSystems ;
    in
      flake-utils.lib.eachSystem systems (system: 
        let 
          systemPkgs = nixpkgs.legacyPackages.${system};
          inherit (systemPkgs) ghcid cabal2nix;
          mkShell = (haskell: 
            let
              # Disable test, hoogle, etc so
              # these shells build as fast as possible.
              hs = haskell.override {
                overrides = self: super: 
                  systemPkgs.lib.mapAttrs (name: value: 
                    if value.isHaskellLibrary or false
                    then systemPkgs.lib.pipe value [
                        systemPkgs.haskell.lib.compose.doJailbreak
                        systemPkgs.haskell.lib.compose.dontCheck
                        systemPkgs.haskell.lib.compose.dontHaddock
                        systemPkgs.haskell.lib.compose.dontBenchmark
                        systemPkgs.haskell.lib.compose.dontHyperlinkSource
                      ]
                    else value
                  ) super;
                };
              in hs.shellFor {
                packages = _: [  ];
                buildInputs = [ hs.cabal-install cabal2nix ghcid ];
                withHoogle = false;
              });
          shell92 = mkShell systemPkgs.haskell.packages.ghc92;
          shell94 = mkShell systemPkgs.haskell.packages.ghc94;
          shell96 = mkShell systemPkgs.haskell.packages.ghc96;
          shell98 = mkShell systemPkgs.haskell.packages.ghc98;
          shell910 = mkShell systemPkgs.haskell.packages.ghc910;
        in 
          { 
            devShell = shell96;
            devShells.default = shell96;
            devShells.ghc92 = shell92;
            devShells.ghc94 = shell94;
            devShells.ghc96 = shell96;
            devShells.ghc98 = shell98;
            devShells.ghc910 = shell910;
          }
      );
}