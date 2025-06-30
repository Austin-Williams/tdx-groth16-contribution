# tdx-groth16-contribution
Performs a Groth16 Phase 2 contribution inside an Intel TDX, producing a .zkey file and a remote attestation that the toxic waste was never accessible to anyone.

## Requirements
- Docker

## Reproducing SnarkJS Binaries
- run `./scripts/build-snarkjs-binary.sh`

Expected SnarkJS reproducible binary hash: sha256:6f487735ab1ad394241391539d7a090892ce9749ea8ce03322ebefd25ac5b582

You can invoke the resulting binary (`./bin/snarkjs-contribute`) from any directory in which a file with the name `tdxInput.zkey` exists. The resulting `tdxOutput.zkey` will be written to the same directory. Note that