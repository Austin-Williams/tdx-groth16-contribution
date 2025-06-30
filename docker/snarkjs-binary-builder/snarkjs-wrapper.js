// Lightweight wrapper that turns the generated self-invoking bundle in
// `snarkjs.js` into a proper ES-module default export.
//
// Usage (ES-module):
//   import snarkjs from './snarkjs-wrapper.js';
//   await snarkjs.zKey.contribute(...);
//
// The wrapper executes the bundle in an isolated `vm` context that shares the
// standard globals it needs (BigInt, WebAssembly, console, etc) and then grabs
// the `snarkjs` variable the bundle leaves behind.

import fs from 'node:fs'
import vm from 'node:vm'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'
import crypto from 'node:crypto'
import { TextEncoder, TextDecoder } from 'node:util'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const require = createRequire(import.meta.url)

// Read the pre-bundled library as plain text.
const bundlePath = path.join(__dirname, 'snarkjs.js')
const bundleCode = fs.readFileSync(bundlePath, 'utf8')

// Prepend fs injection to override the bundle's internal `var fs = {}`
const injectedCode = bundleCode.replace(/\bvar fs = \{\}/g, 'var fs = require("fs")')

// Minimal sandbox with the globals the bundle expects.
const sandbox = {
	console,
	BigInt,
	Uint8Array,
	Uint32Array,
	WebAssembly,
	setImmediate,
	crypto,
	TextEncoder,
	TextDecoder,
	fetch: sandboxFetch,
	Headers,
	Request,
	Response,
	btoa: (str) => Buffer.from(str, 'binary').toString('base64'),
	atob: (str) => Buffer.from(str, 'base64').toString('binary'),
	globalThis: null,
	require,
}

// Ensure globalThis points to the sandbox itself
sandbox.globalThis = sandbox

// Custom fetch that supports local filesystem paths and falls back to global fetch for URLs.
async function sandboxFetch(resource, init) {
	if (typeof resource === 'string' && !/^[a-zA-Z][a-zA-Z\d+.-]*:/.test(resource)) {
		// Treat as local file path.
		const absPath = path.isAbsolute(resource) ? resource : path.resolve(process.cwd(), resource)
		return fs.promises.readFile(absPath).then((buf) => ({
			arrayBuffer: () => buf.buffer.slice(buf.byteOffset, buf.byteOffset + buf.byteLength)
		}))
	}
	return fetch(resource, init)
}

// Run the bundle.  It defines `var snarkjs = (function (exports) { … })({}); `.
vm.runInNewContext(injectedCode, sandbox, { filename: 'snarkjs.js' })

if (!sandbox.snarkjs) {
	throw new Error('Failed to load snarkjs from bundled file.')
}

export default sandbox.snarkjs