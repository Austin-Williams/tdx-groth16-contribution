{
  description = "Minimal hello-world Docker image built by Nix";

  # ----- Pin nixpkgs --------------------------------------------------------
  # 24.05 is the current stable channel (May 2025).  The flake.lock we commit
  # after the first ‘nix flake lock’ will freeze this exact revision forever.
  inputs.nixpkgs.url = "github:nixos/nixpkgs/24.05";

  outputs = { self, nixpkgs }:
  let
    pkgs = import nixpkgs { system = "x86_64-linux"; };
  in
  {
    packages.x86_64-linux.helloImage = pkgs.dockerTools.buildLayeredImage {
      name   = "hello";
      tag    = "latest";
      # ‘contents’ are unpacked into /, so /bin/busybox exists
      contents = [ pkgs.busybox ];
      # │CMD ["sh" "-c" "echo hello world"]│
      config.Cmd = [ "sh" "-c" "echo hello world" ];
    };

    # ‘defaultPackage’ means “nix build .” builds the image tarball
    packages.x86_64-linux.default = self.packages.x86_64-linux.helloImage;
  };
}
