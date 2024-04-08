{
  description = "Linuxing3's NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence";
		    # 新增下面几行
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    lib = nixpkgs.lib;
  in rec {
    nixosConfigurations.bootstrap = lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        inputs.impermanence.nixosModules.impermanence
        ./configuration.nix
        # 新增下面一行
        inputs.disko.nixosModules.disko
      ];
    };
    # 新增下面几行
    packages.x86_64-linux = {
      image = self.nixosConfigurations.bootstrap.config.system.build.diskoImages;
    };
  };
}
