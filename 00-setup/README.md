# 00 — Environment Setup

🟢 **Beginner**

Before you build anything with Yocto, your host machine needs specific packages installed and a Poky clone on disk. This module walks you through both steps on a supported Linux distribution.

---

## What you need

| Requirement | Minimum |
|---|---|
| OS | Ubuntu 22.04 LTS or 24.04 LTS (recommended), Debian 12, Fedora 40 |
| RAM | 8 GB (16 GB recommended for parallel jobs) |
| Disk | 100 GB free (a full build with sstate-cache can exceed 50 GB) |
| CPU | x86-64, any modern multi-core processor |
| Internet | Required for fetching sources during the first build |

> **No physical hardware needed.** Every image you build will run inside [QEMU](https://www.qemu.org/), a software emulator included in the host dependencies.

---

## Supported host distributions

Yocto's Scarthgap (5.0 LTS) release officially supports:

- Ubuntu 22.04 (Jammy) and 24.04 (Noble)
- Debian 12 (Bookworm)
- Fedora 40
- AlmaLinux / Rocky Linux 9

Not on Linux?

- **Windows** — Use WSL2 (Windows Subsystem for Linux 2). See [`docs/wsl2-setup.md`](../docs/wsl2-setup.md).
- **macOS** — Yocto does not run natively on macOS. Use a Linux VM or Docker. See [`docs/macos-setup.md`](../docs/macos-setup.md).

---

## Step 1 — Install host dependencies

Run the provided script as a normal user (it will call `sudo` internally for package installation):

```bash
bash 00-setup/scripts/install-deps.sh
```

The script detects your distribution and installs the correct package set. It will print a summary of what it installed and warn you if anything is missing.

### What gets installed

| Package group | Purpose |
|---|---|
| `git`, `wget`, `curl` | Fetching sources and layers |
| `python3`, `python3-pip` | BitBake runtime and helper scripts |
| `gcc`, `g++`, `make` | Compiling host tools during the build |
| `diffstat`, `patch` | Applying and inspecting patches |
| `chrpath`, `socat` | RPATH manipulation and socket utilities used by `runqemu` |
| `cpio`, `xz-utils` | Packaging and compression |
| `qemu-system-x86` (and arm) | Running the built images |
| `file`, `gawk`, `texinfo` | Build infrastructure utilities |

---

## Step 2 — Clone Poky

[Poky](https://wiki.yoctoproject.org/wiki/Poky) is Yocto's reference distribution. It bundles BitBake (the build engine), OpenEmbedded-Core (the base recipe set), and a set of helper scripts.

Clone the **scarthgap** branch:

```bash
# Pick a location with plenty of disk space — ~/yocto is a common choice
git clone -b scarthgap git://git.yoctoproject.org/poky.git ~/yocto/poky
# Takes 1–3 minutes depending on connection speed
```

---

## Step 3 — Initialise the build environment

Every new terminal session that will run BitBake must source the environment setup script first:

```bash
cd ~/yocto/poky
source oe-init-build-env ../build
```

`oe-init-build-env` does two things:
1. Adds BitBake and Poky's `scripts/` directory to your `PATH`.
2. Creates (or re-enters) the **build directory** at the path you supply (`../build` above).

After sourcing, your shell is inside `~/yocto/build/`. You do not need to `cd` into Poky again for the rest of the session.

---

## Step 4 — Verify the setup

Check that BitBake is on your PATH:

```bash
bitbake --version
# Expected output (exact version may differ):
# BitBake Build Tool Core version 2.8.x
```

Check QEMU is available:

```bash
qemu-system-x86_64 --version
# Expected: QEMU emulator version 8.x.x or newer
```

If either command fails, revisit Step 1 and re-run the dependency script.

---

## Directory layout after setup

```
~/yocto/
├── poky/               ← Poky clone (source of truth, do not edit)
│   ├── bitbake/
│   ├── meta/           ← OpenEmbedded-Core layer
│   ├── meta-poky/      ← Poky distro layer
│   ├── scripts/        ← devtool, runqemu, and other helpers
│   └── oe-init-build-env
└── build/              ← Created by oe-init-build-env
    ├── conf/
    │   ├── local.conf      ← Your machine and build settings
    │   └── bblayers.conf   ← Which layers BitBake sees
    ├── sstate-cache/       ← Shared state cache (speeds up rebuilds)
    └── tmp/                ← All build artefacts (large — can be deleted)
```

---

## Next Steps

Once your environment is set up and `bitbake --version` returns without error, move on to:

➡ [`01-beginner/01-what-is-yocto.md`](../01-beginner/01-what-is-yocto.md) — understand what Yocto actually does before you start building.
