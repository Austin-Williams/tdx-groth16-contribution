#!/usr/bin/env node
// CommonJS entrypoint for SEA build. It dynamically imports the ESM wrapper
// so that the main file itself stays CommonJS (SEA currently only supports
// CommonJS entrypoints).
(async () => {
	const { default: snarkjs } = await import('./snarkjs-wrapper.js')
	const crypto = require('node:crypto')

	await snarkjs.zKey.contribute(
		'./tdxInput.zkey',
		'./tdxOutput.zkey',
		'TDX Contribution',
		crypto.randomBytes(32).toString('hex'),
		console
	)
})()
