# tdx-groth16-contribution
Performs a Groth16 Phase 2 contribution inside an Intel TDX, producing a .params file and a remote attestation that the toxic waste was never accessible to anyone.

## Requirements
- Docker (if you want to rebuild the img yourself and verify its hash)

## Notes
Zokrates reproducible binary hash: sha256:4910d055fec5fdbf08ad92fda82d2227f828257b73d38fa22734bd5e758f1bf6

## Reproducing Zokrates Binaries
(Note: I tested the following using UTM on Apple silicon (M4 Pro) inside an Ubuntu 25.04 - arm64 VM with 16 GB RAM and 4 CPU cores)
- sudo apt-get update
- install git and docker



