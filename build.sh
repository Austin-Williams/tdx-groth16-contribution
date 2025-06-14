#!/usr/bin/env bash
set -euo pipefail

# Nix 2.29.0
NIX_IMG="nixos/nix@sha256:00aa010b193c465d04cba4371979097741965efaff6122f3a268adbfbeab4321"

docker run --rm \
  -e USER="$(id -un)" \
  -e NIX_CONFIG="experimental-features = nix-command flakes" \
  -v "$PWD":/work \
  -w /work \
  $NIX_IMG \
  nix build .#tdxGroth16ContributionImage --print-out-paths
