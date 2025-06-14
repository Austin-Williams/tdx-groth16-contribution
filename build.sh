#!/usr/bin/env bash
set -euo pipefail

# Nix ≥2.17 (supports flake.lock v7)
NIX_IMG="nixos/nix:2.17.0"

docker run --rm \
  -e USER="$(id -un)" \
  -e NIX_CONFIG="experimental-features = nix-command flakes" \
  -v "$PWD":/work \
  -w /work \
  $NIX_IMG \
  nix build .#tdxGroth16ContributionImage --print-out-paths
