{
  description = "Simple Haskell Shell for GHC 9.2, 9.4 and 9.6";

  inputs.nixpkgs.url = "nixpkgs/release-23.05";
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
          shell92 = mkShell systemPkgs.haskell.packages.ghc927;
          shell94 = mkShell systemPkgs.haskell.packages.ghc947;
          shell96 = mkShell systemPkgs.haskell.packages.ghc962;
        in 
          { 
            devShell = shell94;
            devShells.default = shell94;
            devShells.ghc92 = shell92;
            devShells.ghc94 = shell94;
            devShells.ghc96 = shell96;
          }
      );
}