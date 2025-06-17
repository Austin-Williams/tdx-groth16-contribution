# Reproducible Zokrates 0.8.8 Build Plan

## Executive Summary

This document outlines a robust plan for creating a 100% reproducible build process for Zokrates 0.8.8 (linux/amd64). The goal is to enable any auditor to independently verify that the binary used in the TDX enclave is built from the exact source code at the official Zokrates v0.8.8 tag, with bit-for-bit reproducibility.

## Core Requirements

1. **Absolute Reproducibility**: Any auditor running the build script must get the exact same binary (identical SHA-256 hash)
2. **Easy Auditability**: The build script must be simple enough to review and verify correctness
3. **Self-Contained**: No external dependencies beyond Docker or Nix
4. **Verifiable Source**: Build from the official Zokrates repository at the exact v0.8.8 tag

## Technical Approach

### 1. Deterministic Build Environment

We'll use Docker with a fixed base image to ensure environmental consistency:

- **Base Image**: `rust:1.73.0-slim-bullseye` (pinned to specific digest)
  - Already includes the exact Rust toolchain we need, reducing the number of bootstrap steps while still giving us a deterministic Debian 11 base.
- **All dependencies**: Explicitly versioned and hash-verified (probably use debian snapshot)

### 2. Key Reproducibility Factors

#### a. Time Normalization
- Set `SOURCE_DATE_EPOCH` to the commit timestamp of v0.8.8
- Use `--remap-path-prefix` to normalize build paths
- Disable timestamp embedding in compiled artifacts

#### b. Build Determinism
- Use `cargo build --locked` to respect `Cargo.lock`
- Set `RUSTFLAGS` for deterministic compilation:
  - `-C metadata=<fixed-hash>`
  - `-C extra-filename=`
  - `--remap-path-prefix=$HOME=~`
  - `--remap-path-prefix=$PWD=.`

#### c. Binary Post-Processing
- Strip symbols deterministically: `strip --strip-all --preserve-dates`
- Sort sections if needed with `objcopy`
- Verify ELF structure consistency

### 3. Build Script Structure

The `scripts/build-zok-binary.sh` will:

```bash
#!/bin/bash
set -euo pipefail

# 1. Verify we're in a clean environment
# 2. Clone Zokrates at exact commit
# 3. Set up reproducible environment variables
# 4. Build with locked dependencies
# 5. Post-process the binary
# 6. Generate and display checksums
# 7. Save the binary in bin/
# 8. Save a .txt file in bin/ with the sha256 hash of the binary file
```

### 4. Verification Process

Auditors will verify reproducibility by:

1. **Review the build script** - Confirm no hidden logic or external calls
2. **Run the build** - Execute `./scripts/build-zok-binary.sh`
3. **Compare hashes** - Verify SHA-256 matches published value
4. **Build multiple times** - Confirm same output on repeated builds
5. **Cross-verification** - Have multiple independent parties build and compare

### 5. Implementation Plan

#### Phase 1: Environment Setup
- [ ] Create Dockerfile in docker/zok-binary/ with pinned base image
- [ ] Install exact Rust toolchain version
- [ ] Set up all environment variables for reproducibility

#### Phase 2: Build Script Development
- [ ] Create `build-zok-binary.sh` with clear documentation
- [ ] Implement source cloning with commit verification
- [ ] Add reproducible build flags and environment setup
- [ ] Implement deterministic post-processing

#### Phase 3: Testing & Validation
- [ ] Test builds on different machines
- [ ] Verify identical SHA-256 across builds
- [ ] Test with different Docker versions
- [ ] Document any platform-specific considerations

#### Phase 4: Documentation
- [ ] Write clear build instructions
- [ ] Document all reproducibility measures
- [ ] Create troubleshooting guide
- [ ] Provide verification checklist for auditors

### 6. Directory Structure

```
tdx-groth16-contribution/
├── scripts/
│   ├── build-zok-binary.sh        # Main build script
│   └── Dockerfile.zok-builder     # Reproducible build environment
├── dist/
│   ├── zokrates-0.8.8-linux-amd64  # Built binary (COMMITTED TO REPO)
│   ├── checksums.txt               # SHA-256, SHA-512 hashes (COMMITTED)
│   └── build.log                   # Build output for verification
└── docs/
    ├── reproducible-zok-build.md   # This plan
    └── build-verification.md       # Auditor instructions
```

**Note**: The built binary and checksums will be committed to the repository to enable:
- Direct download via scripts without rebuilding
- Easy verification by auditors who can compare their build against the committed version
- Version control tracking of any binary changes

### 7. Security Considerations

- **No network access during build**: All dependencies cached in Docker image
- **Cryptographic verification**: GPG signatures on Rust toolchain
- **Build isolation**: Docker container with minimal privileges
- **Source verification**: Git commit hash verification before build

### 8. Expected Outcomes

Upon successful implementation:

1. Any auditor can run `./scripts/build-zok-binary.sh`
2. The output binary will have SHA-256: `<deterministic-hash>`
3. Multiple builds produce identical binaries
4. The process is transparent and auditable

### 9. Fallback Strategy

If perfect reproducibility proves challenging:

1. **Minimal differences approach**: Document and justify any unavoidable variations
2. **Multi-party builds**: Have 3+ independent parties build and compare
3. **Signed attestations**: Cryptographically sign build outputs

### 10. Success Criteria

The build process is successful when:

- [ ] 5 independent auditors produce identical binaries
- [ ] SHA-256 hashes match across all builds
- [ ] Build script passes security review
- [ ] Documentation is clear enough for non-experts
- [ ] Process works on Ubuntu, Debian, and macOS (via Docker)

## Next Steps

1. Implement the Dockerfile for the build environment
2. Create the build script with extensive comments
3. Test reproducibility across multiple systems
4. Document the verification process for auditors
