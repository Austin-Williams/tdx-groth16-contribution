## How I anticipate users will actually use this tool

I suspect most users will start not with Zokrates, but with [SnarkJs](https://github.com/iden3/snarkjs) because of all the web-facing tooling they have. So I suspect the typical user flow will go like this:

### Install dependencies
- Install Node v24+.
- Install snarkjs: `npm install -g snarkjs@latest`.
- Install [Circom](https://docs.circom.io/getting-started/installation/)

### Write and compile a circuit and witness
- Write a circuit in a `.circom` file. We'll use `example.circom`.
- Compile the circuit: `circom --r1cs --wasm --c --sym --inspect example.circom`. In our example, this creates the following files:
	- `example.r1cs`
	- `example.sym`
	- `example_cpp/<various>`
	- `example_js/<various>`
- View info about the compled circuit, and note the number of constraints (this tells us which PTAU file we need to download):
```
$ snarkjs r1cs info example.r1cs

> [INFO]  snarkJS: Curve: bn-128
> [INFO]  snarkJS: # of Wires: 1003
> [INFO]  snarkJS: # of Constraints: 1000
> [INFO]  snarkJS: # of Private Inputs: 2
> [INFO]  snarkJS: # of Public Inputs: 0
> [INFO]  snarkJS: # of Labels: 1004
> [INFO]  snarkJS: # of Outputs: 1
```
- Note the number of constraints (1000 in this case). We can look up [in this table](https://github.com/iden3/snarkjs?tab=readme-ov-file#7-prepare-phase-2) which PTAU file we need to download. In our case, we'll use `powersOfTau28_hez_final_10.ptau`.
- Create a file containing the (human-readable) witness, to be used for testing the proving system later. We'll use `witness_input.json`.
- Convert that into a `.wtns` file (values for all the wires): `snarkjs wtns calculate example_js/example.wasm witness_input.json example.wtns`. This creates the `example.wtns` file in our example.

### Start the Phase 2 ceremony
- Create an "empty" zkey: `snarkjs groth16 setup example.r1cs powersOfTau28_hez_final_10.ptau empty.zkey`. This creates `empty.zkey` in our example.
- (Optional) Do a quick verification check to make sure the `empty.zkey` was created correctly: `snarkjs zkey verify example.r1cs powersOfTau28_hez_final_10.ptau empty.zkey` (should see `ZKey Ok!`).
- (Optional) Users can pass around this `empty.zkey` and contribute to it just like a normal Phase 2 ceremony. If you do that, just replace the word `empty.zkey` with the name of the last zkey in that chain of contributions when reading the rest of this example. In our example we will assume no other contributions were made before passing the key to the TEE to get its contribution.
- Convert the `empty.zkey` (which is in the format that SnarkJS understands) to an equivalent `tdx-input.params` (which is the format Zokrates understands): `snarkjs zkey export bellman empty.zkey tdx-input.params`. This creates `tdx-input.params` in our example.

### TDX contribution and timestamping
// TODO:
- Use the code in this repo to have the TDX contribute secret randomness to `tdx-input.params` and output `tdx-output.params` and "TD Report" (first step of the remote attestation process):  TODO

- The host gets that TD Quote verified via Intel’s Provisioning Certification Enclave (PCE), producing a "TD Quote" (the actual, full remote attestation that anyone can verify later): TODO

- The host timestamps that "TD Quote" as quickly as possible, ideally by uploading its hash to a blockchain that is expensive to roll back: TODO

- (Optional) Locally check/verify the timestamp, "TD Quote" (Intel signature chain, hash of VM image, system params, etc), and contruibution hash: TODO

// At this point anyone in the future will be able to verify that secure & secret randomness was created and applied inside a TDX to make the contribution with the given contruibution hash.

## Apply a public random beacon

- Convert the `tdx-output.params` file into `tdx-output.zkey` so SnarkJS can understand it: TODO

- Deterministically choose a DRAND round number from the timestamp of the TD Quote from earlier: TODO

- Apply the randomness from that DRAND round to `tdx-output.zkey` as the beacon to create the `final.zkey`: TODO

### (optional) Check that the key can be used for proving
// TODO

### How any future auditor can verify the final.zkey
// TODO
// The two things that they need to verify:
- That the TDX contributed to the key.
	- Get the TD Quote file, hash it, and find its timestamp on-chain.
	- Verify the certchain in the TD Quote (using the timestamp for "now").
	- Verify that the VM hash in the TD quote matches the expected VM hash as per this repo.
	- Verify any other critical components of the TD Quote.
	- Check that the TDX contribution hash is present in the `final.zkey`
- That a secure, public, random beacon was applied as the final contribution.
	- Check that the beacon used to create the `final.zkey` was the randomness from the correct DRAND round.

	