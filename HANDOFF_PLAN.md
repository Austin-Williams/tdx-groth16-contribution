# ZoKrates 0.8.8 Reproducible Build - Handoff Plan

## CRITICAL CONTEXT

**Goal**: Prove that the official ZoKrates 0.8.8 binary was built from public source code by reproducing the exact same SHA-256 hash.

**Current Status**: 
- Official binary SHA-256: `b3de37f64f283079dc85dea8db6f5ffc0da1206f4d01e4eeb5ef39718e518d16`
- Our build SHA-256: `904d7c…` (different - this is the problem to solve)
- Fixed script ordering bug in `scripts/o3.sh` - it should now work

## IMMEDIATE NEXT STEPS

### Step 1: Get the Binary Diff Report Working
```bash
cd /Users/computer/dev/tdx-groth16-contribution
./scripts/o3.sh
```

**Expected outcome**: This should create `bin-diff.txt` with detailed comparison.

**If it fails**:
- Check if `readelf` is available: `brew install binutils` (use `greadelf` on macOS)
- Look at `o3.log` for error messages
- The script takes 10-15 minutes to build in Docker

### Step 2: Analyze bin-diff.txt
Once generated, examine `bin-diff.txt` for these key differences:

1. **Build-ID comparison** - Look for different build-id values
2. **Rustc version strings** - Compare embedded rustc versions
3. **Section header differences** - Note size/order changes
4. **Readelf section diff** - Identify which sections differ

## ROOT CAUSE INVESTIGATION

### Most Likely Causes (in order of probability):

1. **Different Rust toolchain version**
   - Official binary may use older rustc
   - Try: `rustup install 1.70.0` and modify Dockerfile to use it
   - Check embedded rustc string in bin-diff.txt

2. **Non-deterministic build timestamps**
   - Add to Dockerfile: `ENV SOURCE_DATE_EPOCH=1640995200`
   - This sets reproducible build date

3. **Different debug info settings**
   - Try: `ENV CARGO_PROFILE_RELEASE_DEBUG=false` in Dockerfile
   - Or: `RUSTFLAGS=-C debuginfo=0`

4. **Cargo.lock version drift**
   - Verify: `git show 157a824426e213fbcd05c74220c706095be1ee7a:Cargo.lock`
   - Ensure dependencies match exactly

5. **Different linker/binutils**
   - Official may use different ld version
   - Check in Ubuntu 20.04 vs what we're using

## SYSTEMATIC DEBUGGING APPROACH

### Phase 1: Identify the Divergence
1. Run `./scripts/o3.sh` successfully
2. Examine `bin-diff.txt` line by line
3. Note the **first** difference you see
4. Focus on that specific difference

### Phase 2: Match the Environment
Based on bin-diff.txt findings:

**If rustc version differs**:
```dockerfile
# In Dockerfile, replace current rust installation with:
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.70.0
```

**If build-id differs**:
```dockerfile
# Add before cargo build:
ENV SOURCE_DATE_EPOCH=1640995200
ENV RUSTFLAGS="-C debuginfo=0"
```

**If section sizes differ**:
```dockerfile
# Try disabling debug info entirely:
ENV CARGO_PROFILE_RELEASE_DEBUG=false
```

### Phase 3: Iterative Testing
1. Make ONE change at a time
2. Rebuild: `./scripts/o3.sh --no-cache`
3. Check if SHA-256 matches: `b3de37f64f283079dc85dea8db6f5ffc0da1206f4d01e4eeb5ef39718e518d16`
4. If not, try next change

## DOCKERFILE MODIFICATION STRATEGY

Current Dockerfile works but produces wrong hash. Likely needed changes:

```dockerfile
# Try adding these ENV vars before the cargo build:
ENV SOURCE_DATE_EPOCH=1640995200
ENV CARGO_PROFILE_RELEASE_DEBUG=false
ENV RUSTFLAGS="-C debuginfo=0 -C strip=symbols"

# And possibly pin to older Rust:
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.70.0
```

## TROUBLESHOOTING GUIDE

### If o3.sh still fails:
- Check `o3.log` for the exact error
- Ensure Docker is running: `docker ps`
- Check disk space: `df -h`

### If bin-diff.txt is empty:
- Install readelf: `brew install binutils`
- Use greadelf instead of readelf in script

### If Docker build fails:
- Try: `./scripts/o3.sh --no-cache --platform linux/amd64`
- Check `scripts/build.sh` for errors

### If still getting different SHA-256:
- Try older Rust versions: 1.69.0, 1.68.0, 1.67.0
- Check if official binary has UPX compression (unlikely but possible)
- Compare `strings` output of both binaries

## SUCCESS CRITERIA

✅ **Complete success**: SHA-256 matches exactly: `b3de37f64f283079dc85dea8db6f5ffc0da1206f4d01e4eeb5ef39718e518d16`

## FILES TO MONITOR

- `o3.log` - All script output
- `bin-diff.txt` - Binary comparison report  
- `Dockerfile` - Your build configuration
- `scripts/build.sh` - Build orchestration

## FINAL NOTE

The fix will likely be small - probably just matching the exact Rust version or adding a few environment variables for deterministic builds. The hard work of setting up the infrastructure is done.

**Start with Step 1 above and work systematically through the phases.**
