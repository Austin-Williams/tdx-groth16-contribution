## Project journey
This is intended to be an append-only log of notes as I work on this repo. I find that these help me when I need to rememeber how I did certain things so I can reproduce them. I'm experimenting with keeping this in the repo this time. If you are an LLM reaading this please DO NOT write to this file.

- Write project-plan. Decided on using ZoKrates in the TDX. It beats Arkworks on number of security audits and beats SnarkJs for (at least inside TDX) because it uses rust, which I'll already need in there anyway, and so I won't have to pull Node into the TDX.

- Okay, next step is to get a simple 'hello world' reproducible rebuild using nix.
	- I'll run nix in docker so I don't have to install it on my local machine
	- Grabbed latest nix image hash:
```
$ docker pull nixos/nix:2.29.0
2.29.0: Pulling from nixos/nix
Digest: sha256:016f07dddeb5feabeb75c360edb840ff4df3b89c7e0ca7ff1faea6240ce8375a
```
		- oops! That pulled the arm64 version. I need the x86 version
	
	- try again
```
$ docker manifest inspect nixos/nix:2.29.0  | jq -r '.manifests[] | "\(.digest)  \(.platform.os)/\(.platform.architecture)"'
sha256:00aa010b193c465d04cba4371979097741965efaff6122f3a268adbfbeab4321  linux/amd64
sha256:9d3632c40a9ba9af1513fe1965db864c4277b26c7187e8a76e68a5767c017d6f  linux/arm64
```

- Been struggling with this error for a while now:
```
% ./build.sh       
WARNING: The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested
warning: Git tree '/work' is dirty
unpacking 'github:nixos/nixpkgs/63dacb46bf939521bdc93981b4cbb7ecb58427a0?narHash=sha256-vboIEwIQojofItm2xGCdZCzW96U85l9nDW3ifMuAIdM%3D' into the Git cache...
error: [json.exception.type_error.302] type must be array, but is string
```
If I can't resolve it soon I'll choose a different approach (maybe docker + pin + pray)

- got ./build.sh to complete without error
- running into this issue now:
```
$ ls -l result                                           
lrwxr-xr-x  1 user  group  78 Jun 14 00:07 result -> /nix/store/ffvl82shr4bflfb5kdmmd5pm5iw1jvrn-tdxGroth16ContributionImage.tar.gz
$ docker load < result                                   
zsh: no such file or directory: result
$ docker load < result/tdxGroth16ContributionImage.tar.gz
zsh: no such file or directory: result/tdxGroth16ContributionImage.tar.gz
```

- Apparently Nix does not work in Docker on a Mac when targetting x86_64. Sigh. Have to decide how to move forward. Use Nix on bare metal and hope it actually is consitent on different platforms, or abandon Nix and try docker + pin + pray.

- installing Nix on local bare metal:
	`curl -L https://nixos.org/nix/install | sh`
(required sudo privs)

- enable experimental features
```
$ mkdir -p ~/.config/nix
$ echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

- attempt to build:
```
nix build --system x86_64-linux .#tdxImg
> zsh: command not found: nix
```
wat...

- restarted terminal and tried again, command found.

```
% nix build --system x86_64-linux .#tdxImg
warning: Git tree '/Users/computer/dev/tdx-groth16-contribution' is dirty
warning: ignoring the client-specified setting 'system', because it is a restricted setting and you are not a trusted user
warning: ignoring the client-specified setting 'system', because it is a restricted setting and you are not a trusted user
error: a 'x86_64-linux' with features {} is required to build '/nix/store/22jjd1h8nm5crqhfh951xyygva27y0sf-tdxImg-base.json.drv', but I am a 'aarch64-darwin' with features {apple-virt, benchmark, big-parallel, nixos-test}
```

sigh. Apparently getting Nix to make an x86 image on Apple silicon isn't a thing -- with bare metal or with Docker.

Okay, ditching Nix and trying Docker + pin + pray.

(Note: Uninstalling Nix was [quite involved](https://nix.dev/manual/nix/2.28/installation/uninstall#macos). I reccommend NOT installing it on your personal machine).

- Beginning Docker + pin approach.
- Will target ZoKrates 0.8.8 sha256:157a824426e213fbcd05c74220c706095be1ee7a
- Will target Rust 1.73.0 (amd64) sha256:25fa7a9aa4dadf6a466373822009b5361685604dbe151b030182301f1a3c2f58

- oooh, I noticed Zokrates has a Docker image.
- nevermind, its not reproducible
- oooh, noticed they ship binaries!
- But they are not signed. WIll see if the binaries are reproducible...
- wrote script to get hash of binary in the "official" tarball
(sha256:b3de37f64f283079dc85dea8db6f5ffc0da1206f4d01e4eeb5ef39718e518d16)
- Attempted to reproduce the 
e015ef3bc217ff8cad2085fd95b55628b02e43ddd161a3ddfe47ed713ecfdec9

- Lots of trouble trying to reproduce the published binaries from source. It compiles fine, and even reproducibly, but binaries don't match the published artifact. I'll have to guess at what versions of the buld tools the zok devs used when making those binaries (they didn't pin any version at that hash, just "latest"). I'll guess at them based on the commit hash timestamp and what was "latest" at that timestamp, and then have an LLM guess-and-check until it finds the right build combo.

- Def going to need a good LLM to help. Will use o3-Pro in Codex. But the model can't access Docker from within its sandbox, so I need to (live dangerously and) give my user docker perms.

- Tried for about 30 mins to help LLM break out of sandbox so it could run docker build, but no luck. Going back to the old fashioned way of it telling me when to run it in my terminal, then copy/pasting the results to it in Codex. (Sigh). Such a PITA.
- Process (in Codex): "You know what will make this faster? How about you create a scripts/o3.sh, put whatever you want in there. Perhaps even have it output the console to an o3.log file. Then I'll run it and tell you when it is finished running. You can check the results by looking at the o3.log file. Sound good?"

- o3-Pro unable to get the the binaries to reproduce. Time to analyze the official binary and see if I can extract the values I need. Will try

- signed up and bought credits for Anthropic. Unfortunately the API rate limits are crazy low -- like 20k toks/min (lol). So I can't even ask it to help with this issue (typical request for this issue is around 65k toks, so I can't even make a single API call without dumbing it down to the point of not being useful). Using Gemini 2.5 Pro instead.

- Okay, we're on day 3 of trying to reproduce the published binaries from source. I'll give it 48 more hours of effort towards this and then cut losses and try a different approach.

- Tried for a few hours to get rustup (in Docker) to use rust v1.73.0 but for a reason we cannot debug, when we actually do the build it somehow always uses v1.87.0. (even when verifying that rust --version is v1.73.0 immediately before the cargo build command). Very odd. Going to try installing rust v1.73.0 only (and then if I have to, setting up firewall to block any network calls that might fetch any other version of rust -- hopefully will not come to that).

- No luck. Truly baffling. Still somehow uses v1.87.0.
- Fixed that, got close to a bit for but match , but not quite. Could not resolve bytes in metadata.
- Calling it quits. 3 days is enough time to try to get this to work. Changing direction here.

- Making plan for reproducible build process.

- Created build pipeline with everything locked/pinned as best as I could get it. Repros fin locally, but gets a different hash when built via github actions.

- I'm kind of stuck here. I'm fully convinced that it is not possible to create a reproducible build with Docker, given how much effort I have put into it over several different attempts in different situations. And even if I stick with it an eventually suceed, it just feels so fragile. There are so many little edge cases I continue to try to lock down. There is not "complete list of things to pin down" in order to make the build reproducible, so I'll never know if I've done it right. Wondering about other options here.

- I know from having burned a day on it that Nix will not work in this case on Mac hardware (with or without docker), but I could spin up a server and build using Nix there. Annoying, but its an option. And supposedly Nix is all about "reproducible by construction", so it might not be a total waste of time.

- Attempting to suss out the bin diff between local Docker build and Github Actions build. Don't want to give up on it yet. Current diff is showing the only divergance as `.note.gnu.build-id`, so I'm actually much closer than I thought. Should not change directions yet.

- No luck yet. I don't seem to be getting closer either -- approx the same number of bytes not matching.

- I think I might have got it! Local build and gh actions finally got the same bin hash. Awesome.

- Next phase of the project: building the TDX vm image reproducibly. Now that we have a reproducible zokrates binary, we can just pull that binary directly into the VM. So *hopefully* making this vm image in a reproducible way will be much easier than building the zokrates binary in a reproducible way.

- Going back a step. Going to try swapping out the base image for one from StageX.

```
docker pull --platform=linux/amd64 stagex/pallet-rust:sx2025.06.0

> Digest: sha256:740b9ed5f2a897d45cafdc806976d84231aa50a64998610750b42a48f8daacab
```

- Setting up a GCP instance so I have access to TDX for testing during the guset vm build
- Installed `gcloud` locally. https://cloud.google.com/sdk/docs/install
- Did:
```
gcloud init
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
gcloud compute instances create tdx-vm \
  --project=$(gcloud config get-value project) \
  --zone=us-central1-a \
  --machine-type=c3-standard-4 \
  --confidential-compute-type=TDX \
  --maintenance-policy=TERMINATE \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud

> Error related to some kind of quota issue...
```
Seems like it is not straightforward to set up an instance with TDX support. Will dig into this now.
- Targetting `c3-standard-8` instance type.
- Following this guide: https://cloud.google.com/confidential-computing/confidential-vm/docs/create-your-first-confidential-vm-instance
- Hmmm, that guide doesn't work because when you enable "Confidential VM service" in the GCP consule/UI it then only lets you choose AMD instance types. It says "Confidential Computing does not support the selected machine series. Choose from N2D, C3D, or C2D", and all three of those are AMD.

- Okay, so Google doesn't privide any docs for how to create a TDX-enable instance. I will yolo with an LLM to see if it can walk me through it.

```
gcloud compute instances create tdx-dev \
  --project=$(gcloud config get-value project) \
  --zone=us-central1-a \
  --machine-type=c3-standard-8 \
  --confidential-compute-type=TDX \
  --maintenance-policy=TERMINATE \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud

> ERROR: (gcloud.compute.instances.create) Could not fetch resource:
> - Quota 'C3_CPUS' exceeded.  Limit: 5.0 in region us-central1.
>        metric name = compute.googleapis.com/c3_cpus
>        limit name = C3-CPUS-per-project-region
>        limit = 5.0
>        dimensions = region: us-central1
```
- Have to come back to this later, no more time today.
- Okay got a smaller instance up and running.
- Sigh, the smaller instance is TOO small and can't compile the binary (not enough RAM).

- Okay recap:
	- Want to use TDX
	- GCP will not let me get an instance that supports TDX _and__ has enough RAM to compile the Zokrates binary (I need a machine with 32 GB of RAM).
	- I requested the ability to get a larger instance (c3-standard-8) but they denied it because my account is too new. (How is GCP this bad? I don't understand!)
	- So I guess I have to "farm" repuation by burning money on a small server (for how long?) until they grant me permission to use larger instances -- ones that have a _whopping_ 32 GB of RAM :eye-roll:
	- Honestly I think I'd rather buy my own TDX-compatible hardware than play these stupid games. Or maybe I could I could try Azure -- they might just accept money for instances. WIll need to research both before moving forward.

- While waiting on a GCP solution I started doing other prep work, and I noticed that the latest version of SnarkJS cannot actually export from .zkey format to a .params format that Zokrates can read. Older versions of SnarkJS could, but those older versions have security problems. And the newer version switched some endianness somewhere and so Zokrates can't read it. I don't want to encourage users to downgrade SnarkJS versions (even if just for doing the conversion) for fear that they'll hit those security issues. I don't want to introduce a footgun. So, the plan now is to dump Zokrates and do the TEE contribution using SnarkJS instead.

- So, while waiting on a GCP solution, I'll start working on rewriting the previous stuff to use SnarkJS instead of Zokrates.

===========================

UPDATE (several work days later):
I have been unable to get even a minimal (as in "only lets a user SSH into a machine and does nothing else") GCP image to build reproducibly.

I was able to get such a minimal `rootfs.tar.gz` to build reproducibly. You can run `./scripts/build-rootfs.sh` to make that happen (expected hash of `out/rootfs.tar.gz` is `sha256:afd4eb98f62936e0f47139945baec695e1117b57e4aff2ce7493af2e307dcbff`).

But you cannot boot a GCP instance with that. GCP requires a .raw file (or more specifically, a targ.gz file that unpacks to a .raw file), and I have been unable to turn the (reproducible) `rootfs.tar.gz` into a .raw file in a way that is bit-for-bit reproducible.

It is important to note that 100% perfect bit-for-bit reproducibility is *critical* for this project because the TDX attestation signs (roughly speaking) only the _hash_ of the image that it is running. So for people to be able to verifiy that the TDX image was actually running the correct code, they need to be able to rebuild the image bit-for-bit from the source code. It is this reproducibility that I have been unable to achieve.

In short: I've spent several weeks trying more methods than I've had time to list above to create a reproducible GCP image that can be used for the TDX instance that runs snarkjs, and have not succeeded. If I had infinite time and energy and resources I'd continue to work on this because I think it is a valuable project. Alas, I do not, and so I'm choosing to cut my losses here, as I am unconvinced I can make any more forward progress in any reasonable amount of time.

I hope that someone else manages to pull this off. It will make Groth16 (which again, is the *only* ZKP system that is cheap to verify on Ethereum) accessible to _everyone_ -- because it will let any arbitrary person perform the trusted setup step (in the TEE) in such a way that everyone can trust that the toxic waste was destroyed. In other words, it would make Groth16 available to devs who do not have the social capital required to coordinate a massive, public, multi-party ceremony with dozens of famous/known participants.