# Yocto on macOS

Yocto does **not** support macOS as a native host. The build system relies on GNU toolchain behaviour, case-sensitive filesystems, and Linux-specific kernel interfaces that macOS cannot provide. Attempting to run BitBake directly on macOS will fail.

You have two practical options:

| Option | Best for | Difficulty |
|---|---|---|
| [Linux VM](#option-1--linux-vm) | Most users — full Linux environment, straightforward | Easy |
| [Docker / CROPS](#option-2--docker--crops) | Users who prefer containers, or who already use Docker | Medium |

Both options are covered below. Pick one and follow it start to finish, then return to [`00-setup/README.md`](../00-setup/README.md) for the rest of the setup.

---

## Option 1 — Linux VM

A Linux virtual machine gives you a full, native Linux environment. This is the most reliable path and the one most Yocto developers on macOS use.

### Recommended VM software

| Software | Intel Mac | Apple Silicon (M1/M2/M3) | Cost |
|---|---|---|---|
| [UTM](https://mac.getutm.app) | ✅ | ✅ | Free |
| [VirtualBox](https://www.virtualbox.org) | ✅ | ✅ (experimental) | Free |
| [Parallels Desktop](https://www.parallels.com) | ✅ | ✅ | Paid |
| [VMware Fusion](https://www.vmware.com/products/fusion.html) | ✅ | ✅ | Free for personal use |

**UTM is recommended for Apple Silicon Macs.** VirtualBox's Apple Silicon support is still experimental and slower. Parallels and VMware Fusion both work well but are commercial products.

---

### Step 1 — Download Ubuntu 22.04 LTS

- **Intel Mac**: Download the standard x86-64 ISO from [ubuntu.com/download/desktop](https://ubuntu.com/download/desktop). Choose Ubuntu 22.04 LTS or 24.04 LTS.
- **Apple Silicon Mac**: Download the ARM64 server ISO from [ubuntu.com/download/server/arm](https://ubuntu.com/download/server/arm). Ubuntu 22.04 LTS or 24.04 LTS.

> Yocto Scarthgap supports both x86-64 and AArch64 host machines, so either architecture works.

---

### Step 2 — Create the VM

#### UTM (recommended for Apple Silicon)

1. Open UTM → **Create a New Virtual Machine** → **Virtualize** (not Emulate).
2. Select **Linux**.
3. Boot ISO image: browse to the Ubuntu ISO you downloaded.
4. Set RAM to at least **8 GB** (12–16 GB recommended).
5. Set CPU cores to at least **4** (match your Mac's performance cores).
6. Set storage to at least **150 GB** — Yocto builds are large.
7. Complete the wizard and start the VM.

#### VirtualBox

1. **New** → Name: `Ubuntu-Yocto`, Type: Linux, Version: Ubuntu (64-bit).
2. RAM: 8 GB minimum.
3. Create a virtual hard disk: **VDI**, dynamically allocated, **150 GB**.
4. Settings → Storage → attach the Ubuntu ISO to the optical drive.
5. Settings → System → Processor: set to 4+ CPUs.
6. Start the VM and install Ubuntu.

#### Parallels / VMware Fusion

Both have guided installers that detect the ISO automatically. Set RAM ≥ 8 GB and disk ≥ 150 GB when prompted.

---

### Step 3 — Install Ubuntu

Follow the Ubuntu installer. Recommended settings:

- **Installation type**: Normal installation (not minimal — you want build tools available)
- **Disk**: use the entire virtual disk
- Create a user account (any username is fine)
- Do **not** encrypt the disk (adds complexity with no benefit in a VM)

After installation, reboot the VM and log in.

---

### Step 4 — Configure the VM for Yocto

Inside the Ubuntu VM, update the system and install VM guest tools:

```bash
sudo apt-get update && sudo apt-get upgrade -y

# UTM / QEMU guest tools (UTM only)
sudo apt-get install -y spice-vdagent

# VirtualBox guest additions (VirtualBox only)
sudo apt-get install -y virtualbox-guest-utils virtualbox-guest-x11
```

Reboot the VM after installing guest tools to enable shared clipboard, dynamic resolution, and shared folders.

---

### Step 5 — Allocate disk space carefully

By default the VM disk starts small and grows dynamically. Yocto builds can consume 80–100 GB. Make sure the VM disk is large enough **before** you start building — expanding a full disk inside a running VM is more painful than allocating space upfront.

Check available space:

```bash
df -h /
# Avail column should show 100+ GB
```

---

### Step 6 — Continue with the standard setup

Inside your Ubuntu VM, follow the standard instructions:

```bash
bash ~/path/to/yocto-on-pc/00-setup/scripts/install-deps.sh
```

Then continue from **Step 2** in [`00-setup/README.md`](../00-setup/README.md).

---

### Performance tips for VMs on macOS

- **Give the VM at least half your Mac's RAM.** BitBake spawns many parallel tasks; memory pressure stalls builds.
- **Store the VM disk on your Mac's internal SSD**, not an external drive. VM disk I/O is the primary bottleneck.
- **Use virtio disk and network drivers** (UTM and VMware do this by default; VirtualBox may need manual configuration) for better I/O performance.
- **Disable macOS Spotlight indexing** of the directory where the VM disk file lives — scanning gigabytes of temporary build artefacts slows both macOS and the VM.

---

## Option 2 — Docker / CROPS

The [CROPS project](https://github.com/crops/poky-container) (Containers for Yocto Project) provides official Docker images that contain a complete Yocto build environment. This lets you run BitBake inside a container without a full Linux VM.

### Prerequisites

- [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/) installed and running.
- Docker Desktop configured with sufficient resources:
  - CPUs: 4 or more
  - Memory: 8 GB or more
  - Disk image size: 150 GB or more (Settings → Resources → Advanced)

> **Apple Silicon note:** Docker Desktop on Apple Silicon runs containers in a Linux VM under the hood (using QEMU or Apple's Virtualization framework). Performance is good but slightly lower than native. All x86-64 CROPS images work on Apple Silicon via emulation; use `--platform linux/amd64` if needed.

---

### Step 1 — Pull the CROPS Poky container

```bash
docker pull crops/poky:ubuntu-22.04
```

This image contains all Yocto host dependencies pre-installed. It is large (~1–2 GB compressed).

---

### Step 2 — Prepare a work directory on your Mac

BitBake writes tens of gigabytes of data. Use a dedicated directory on your Mac's SSD, mounted into the container:

```bash
mkdir -p ~/yocto-workdir
```

---

### Step 3 — Run the container

```bash
docker run --rm -it \
    --volume ~/yocto-workdir:/workdir \
    crops/poky:ubuntu-22.04 \
    --workdir=/workdir
```

This drops you into a shell inside the container with `/workdir` mapped to `~/yocto-workdir` on your Mac. Your build files persist on your Mac even after the container exits.

---

### Step 4 — Clone Poky and build inside the container

```bash
# Inside the container shell:
cd /workdir
git clone -b scarthgap git://git.yoctoproject.org/poky.git poky
source poky/oe-init-build-env build
bitbake core-image-minimal
```

---

### Step 5 — Running QEMU inside Docker

QEMU requires kernel-level virtualisation that Docker Desktop on macOS does not expose to containers. Use `slirp` mode and run `runqemu` with the `nonetwork` or `slirp` option:

```bash
# Inside the container:
runqemu qemux86-64 core-image-minimal nographic slirp
```

If `runqemu` fails to find a display or audio device, add `nographic` and `audio=none`:

```bash
runqemu qemux86-64 core-image-minimal nographic slirp \
    QB_AUDIO_DRV="" QB_AUDIO_OPT=""
```

---

### Limitations of the Docker approach

| Limitation | Impact |
|---|---|
| File I/O through Docker volume mount is slower than native | Builds take longer than in a VM |
| No hardware KVM acceleration | QEMU guest runs slower |
| Container is stateless — only `/workdir` persists | Do not store anything outside `/workdir` |
| Some `runqemu` networking modes unavailable | Use `slirp` for guest networking |

For occasional builds or CI use, Docker works well. For daily development, a VM gives a more seamless experience.

---

## Choosing between the two options

- **New to Linux / want the simplest experience** → VM (Option 1). Once set up, it behaves identically to a native Linux machine and every command in this tutorial works without modification.
- **Already use Docker / want to avoid a full VM** → CROPS (Option 2). More setup friction for QEMU, but no VM to manage.
- **Apple Silicon Mac doing serious development** → VM with UTM. UTM uses Apple's Virtualization framework for near-native ARM Linux performance.

---

## Returning to the main setup

Once you have a working Linux environment (VM or container), continue from:

➡ [`00-setup/README.md`](../00-setup/README.md) — Step 1 (install host dependencies)
