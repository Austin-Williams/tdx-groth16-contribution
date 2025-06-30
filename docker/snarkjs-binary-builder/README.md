The `snarkjs.js` file was downloaded from https://github.com/iden3/snarkjs/blob/0e0126f427f5c2c8ec753bc0d60dfacc6afece16/build/snarkjs.js

The commit hash corresponds to SnarkJS v0.7.5.

I removed from the end of the file the giant comment that embeds the entire source-map JSON. It does not impact the runtime (it is just a comment) and significantly reduces filesize.

Auditors should do a simple diff check to verify.