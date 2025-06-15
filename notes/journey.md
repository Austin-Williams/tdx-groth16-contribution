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

(Note: Uninstalling Nix was [quite involved](https://nix.dev/manual/nix/2.28/installation/uninstall#macos). I highly reccomend NOT installing it on your personal machine).

