# tdx-groth16-contribution
Performs a Groth16 Phase 2 contribution inside an Intel TDX, producing a .params file and a remote attestation that the toxic waste was never accessible to anyone.

## Requirements
- Docker (if you want to rebuild the img yourself and verify its hash)

## Notes
Zokrates reproducible binary hash: sha256:b76ebf790b89084aa91a0224bd4ae3c19e96371ba694fe1a7122f04759faeb86

## Reproducing Zokrates Binaries
(Note: I tested the following using UTM on Apple silicon (M4 Pro) inside an Ubuntu 25.04 - arm64 VM with 16 GB RAM and 4 CPU cores)
- sudo apt-get update
- install git and docker



