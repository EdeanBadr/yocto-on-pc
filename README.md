# Yocto on PC

Learn the Yocto Project from scratch — no hardware required. Every image you build runs inside QEMU, a software emulator that runs on your existing computer.

This repository is a structured tutorial that takes you from zero to building custom embedded Linux images, writing BSP layers, and configuring the Linux kernel. All on Yocto **Scarthgap (5.0 LTS)**.

---

## Who this is for

| Level | You should start here |
|---|---|
| Never used Yocto before | [00-setup/](00-setup/README.md) → [01-beginner/](01-beginner/README.md) |
| Comfortable with BitBake basics | [02-intermediate/](02-intermediate/README.md) |
| Writing layers and recipes already | [03-advanced/](03-advanced/README.md) |

---

## What you will learn

### 🟢 Beginner
- What Yocto is and how it differs from a regular Linux distribution
- How to configure `local.conf` and run your first build
- How to boot your image in QEMU with `runqemu`
- What is actually inside a minimal embedded Linux image

### 🟡 Intermediate
- How layers are structured and how BitBake discovers them
- How to write a recipe for your own C program
- How to add packages to an image via `IMAGE_INSTALL`
- How to create a custom image recipe in your own layer
- How to use `devtool` for fast iterative development

### 🔴 Advanced
- What a BSP layer contains and why
- How to write a custom machine definition for a QEMU target
- How the `linux-yocto` kernel configuration system works
- How to write and apply kernel configuration fragments
- How to pull everything together into a reproducible custom machine + image

---

## Prerequisites

- A Linux PC, or Windows with WSL2, or macOS with a Linux VM
- 8 GB RAM minimum (16 GB recommended)
- 100 GB free disk space
- Basic Linux command-line familiarity

No embedded hardware. No cross-compile toolchain installed in advance. Yocto builds its own.

---

## Quick start

```bash
# 1. Clone this repo
git clone https://github.com/EdeanBadr/yocto-on-pc.git
cd yocto-on-pc

# 2. Install host dependencies
bash 00-setup/scripts/install-deps.sh

# 3. Clone Poky (Scarthgap branch)
git clone -b scarthgap git://git.yoctoproject.org/poky.git ~/yocto/poky

# 4. Initialise the build environment
source ~/yocto/poky/oe-init-build-env ~/yocto/build

# 5. Build a minimal image (takes 1–4 hours on first run)
MACHINE=qemux86-64 bitbake core-image-minimal

# 6. Boot it
runqemu qemux86-64 core-image-minimal nographic
```

Then follow the modules in order for a full explanation of every step.

---

## Repository structure

```
yocto-on-pc/
├── 00-setup/               ← Host setup: packages, Poky clone, environment
├── 01-beginner/            ← What is Yocto, first build, QEMU boot, exploration
├── 02-intermediate/        ← Layers, recipes, packages, custom images, devtool
├── 03-advanced/            ← BSP layers, kernel configuration, custom machine
├── docs/
│   ├── glossary.md         ← Definitions for every Yocto term used here
│   ├── troubleshooting.md  ← Common errors and fixes
│   ├── wsl2-setup.md       ← Windows users: WSL2 setup guide
│   └── macos-setup.md      ← macOS users: VM and Docker options
└── resources.md            ← Official docs, community links, cheat sheets
```

---

## Not on Linux?

- **Windows** — use WSL2: [docs/wsl2-setup.md](docs/wsl2-setup.md)
- **macOS** — use a Linux VM or Docker: [docs/macos-setup.md](docs/macos-setup.md)

---

## Yocto release

All content targets **Scarthgap (5.0 LTS)**, released April 2024 and supported until April 2028. Layer branches, variable names, and commands are specific to this release.
