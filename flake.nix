{
  description = "Minimal hello-world Docker image built by Nix";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/24.05";

  outputs = { self, nixpkgs }:
  let
    pkgs = import nixpkgs { system = "x86_64-linux"; };
  in
  {
    packages.x86_64-linux.tdxGroth16ContributionImage = pkgs.dockerTools.buildLayeredImage {
      name   = "tdxGroth16ContributionImage";
      tag    = "latest";
      contents = [ pkgs.busybox ];
      config = {
        Cmd = [ "sh" "-c" "echo hello world" ];
      };
    };

    packages.x86_64-linux.default = self.packages.x86_64-linux.tdxGroth16ContributionImage;
  };
}
