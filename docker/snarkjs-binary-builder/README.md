## Reproducing the snarkjs-contribute binary
- run `./scripts/build-snarkjs-binary.sh`

Expected snarkjs-contribute binary hash: sha256:6f487735ab1ad394241391539d7a090892ce9749ea8ce03322ebefd25ac5b582

## Using the binary
You can invoke the resulting binary (`./bin/snarkjs-contribute`) from any directory in which a file with the name `tdxInput.zkey` exists. The resulting `tdxOutput.zkey` will be written to the same directory.

## Notes
The `snarkjs.js` file was downloaded from https://github.com/iden3/snarkjs/blob/0e0126f427f5c2c8ec753bc0d60dfacc6afece16/build/snarkjs.js

The commit hash corresponds to SnarkJS v0.7.5.

I removed from the end of that `snarkjs.js` file the giant comment that embeds the entire source-map JSON. It does not impact the runtime (it is just a comment) and significantly reduces filesize.

Auditors should do a simple diff check between the original `snarkjs.js` file and the one in this repo to verify this for themselves.