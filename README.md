# tdx-groth16-contribution
Performs a Groth16 Phase 2 contribution inside an Intel TDX, producing a .zkey file and a remote attestation that the toxic waste was never accessible to anyone.

## Requirements
- [NodeJS 24+](https://github.com/nvm-sh/nvm?tab=readme-ov-file#installing-and-updating)
- [Docker](https://docs.docker.com/engine/install/debian/)

## Reproducing SnarkJS Binaries
- add user to docker group `sudo usermod -aG docker $USER && newgrp docker`
- run `./scripts/build-snarkjs-binary.sh`


Expected SnarkJS reproducible binary hash: sha256:6f487735ab1ad394241391539d7a090892ce9749ea8ce03322ebefd25ac5b582

You can invoke the resulting binary (`./bin/snarkjs-contribute`) from any directory in which a file with the name `tdxInput.zkey` exists. The resulting `tdxOutput.zkey` will be written to the same directory. Note that

## TDX-Image notes
- Build: `./scripts/build-tdx-image.sh`
- Export: `docker container create --name tdx-export tdx-image > /dev/null && docker export tdx-export | gzip > tdx-image.tar.gz && docker rm tdx-export`
- Pick/create a GCS bucket: `gsutil mb -p <PROJECT_ID> gs://my-tdx-images/`
- Upload the tarball: `gsutil cp tdx-image.tar.gz gs://my-tdx-images/`

rootfs.tar.gz
sha256:7f3e54beda1477973af852152555cdb335115fd3b8cc93daf898b0862bcf3cc7