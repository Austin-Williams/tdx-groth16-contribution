> This was an asperational project. I gave it my best attempt, but was unable to see it through to completion. See the end of `notes/journey.md` for a summary.

# tdx-groth16-contribution
Performs a Groth16 Phase 2 contribution inside an Intel TDX, producing a .zkey file and a remote attestation that the toxic waste was never accessible to anyone.

## Requirements
- Docker Engine ≥ 20.10 or Docker Desktop ≥ 4.x

## Reproducing Binaries and images
- Ensure your user can talk to Docker (add to `docker` group if necessary).

```bash
# yeilds ./out/rootfs.tar.gz
# expeced digest: sha256:b155165186a190ed84104ddacbb4f4eee19fb98a051d39a759ba37865720b285
./scripts/build-rootfs.sh
```

Expected SnarkJS reproducible binary hash: sha256:6f487735ab1ad394241391539d7a090892ce9749ea8ce03322ebefd25ac5b582

You can invoke the resulting binary (`./bin/snarkjs-contribute`) from any directory in which a file with the name `tdxInput.zkey` exists. The resulting `tdxOutput.zkey` will be written to the same directory. Note that

## Building the GCP custom image
Assuming you already produced `out/tdx-rootfs.tar.gz` as above:

```bash
# will emit out-img/disk.raw and out-img/tdx-image.tar.gz

docker buildx build \
  --build-context rootfs=out \
  --no-cache --pull --platform linux/amd64 \
  --target export \
  --output type=local,dest=out-img \
  docker/gcp-image-builder
```

The final `tdx-image.tar.gz` is what `gcloud compute images import` expects.

## TDX-Image notes
- Build: `./scripts/build-tdx-image.sh`
- Export: `docker container create --name tdx-export tdx-image > /dev/null && docker export tdx-export | gzip > tdx-image.tar.gz && docker rm tdx-export`
- Pick/create a GCS bucket: `gsutil mb -p <PROJECT_ID> gs://my-tdx-images/`
- Upload the tarball: `gsutil cp tdx-image.tar.gz gs://my-tdx-images/`


afd4eb98f62936e0f47139945baec695e1117b57e4aff2ce7493af2e307dcbff  out/rootfs.tar.gz
cd059e44ce2723bb1e7800b50292a8d201d704de9a3c59639373cf14849f84bc  out/rootfs.raw
5fc59c2e3b6d7021a3fab2ebf508c0dea3055b090513bb9a6d0df776d119a478  out/rootfs.raw.tar.gz