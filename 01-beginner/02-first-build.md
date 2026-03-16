# Your First Build

🟢 **Beginner**

In this module you configure your build directory and run `bitbake core-image-minimal` for the first time. The build will download sources from the internet and compile a minimal Linux image from scratch. Expect it to take **1–4 hours** on a typical machine.

---

## Prerequisites

- Environment set up per [`00-setup/README.md`](../00-setup/README.md)
- Poky cloned to `~/yocto/poky` (scarthgap branch)
- At least 80 GB free disk space

---

## Step 1 — Source the environment

Every terminal session that runs BitBake must start by sourcing `oe-init-build-env`. This adds BitBake and Poky's scripts to your `PATH` and drops you into the build directory.

```bash
cd ~/yocto/poky
source oe-init-build-env ../build
# Your shell is now inside ~/yocto/build/
```

You will see output like:

```
You had no conf/local.conf file. This configuration file has therefore been
created for you with some default values. ...

### Shell environment set up for builds. ###
```

`oe-init-build-env` creates `build/conf/local.conf` and `build/conf/bblayers.conf` on the first run. You only edit these two files to control your build.

---

## Step 2 — Edit local.conf

`local.conf` is your primary build configuration file. Open it:

```bash
# You are already inside ~/yocto/build/
nano conf/local.conf
# or: vim conf/local.conf, gedit conf/local.conf, etc.
```

Make the following changes:

### Set the machine target

Find the `MACHINE` line (it may be commented out with `#`). Set it to `qemux86-64`:

```conf
MACHINE ?= "qemux86-64"
```

The `?=` operator means "set this value only if it is not already set elsewhere" — a safe default that lets you override from the command line.

### Tune parallel job counts

Find and update these two variables to match your CPU core count. For a 4-core machine:

```conf
BB_NUMBER_THREADS ?= "4"
PARALLEL_MAKE ?= "-j4"
```

`BB_NUMBER_THREADS` controls how many BitBake tasks run in parallel. `PARALLEL_MAKE` is passed to `make` inside each recipe. A common rule of thumb: set both to your core count, or up to 1.5× if you have fast I/O.

### Enable the sstate-cache (already on by default)

The [sstate-cache](../docs/glossary.md#sstate-cache) stores compiled task outputs. If the cache already exists from a previous build, BitBake reuses results instead of recompiling. Check that this line is present and not commented out:

```conf
SSTATE_DIR ?= "${TOPDIR}/sstate-cache"
```

`${TOPDIR}` expands to your build directory (`~/yocto/build`), so the cache lives at `~/yocto/build/sstate-cache/`.

### Save and close local.conf

You do not need to change anything else for this first build.

---

## Step 3 — Inspect bblayers.conf

`bblayers.conf` tells BitBake which layers to include in the build. Open it to see the default:

```bash
cat conf/bblayers.conf
```

```conf
# POKY_BBLAYERS_CONF_VERSION is increased each time build/conf/bblayers.conf
# changes incompatibly
POKY_BBLAYERS_CONF_VERSION = "2"

BBPATH = "${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " \
  /home/you/yocto/poky/meta \
  /home/you/yocto/poky/meta-poky \
  /home/you/yocto/poky/meta-yocto-bsp \
  "
```

Three layers are enabled by default:

| Layer | Contents |
|---|---|
| `meta` | OpenEmbedded-Core: toolchain, libc, BusyBox, and thousands of base recipes |
| `meta-poky` | Poky distro configuration (`DISTRO = "poky"`) |
| `meta-yocto-bsp` | BSP definitions for QEMU targets |

You do not need to change `bblayers.conf` for this build.

---

## Step 4 — Run the build

Start the build:

```bash
# This takes 1–4 hours on first run — subsequent builds are much faster
bitbake core-image-minimal
```

`core-image-minimal` is a recipe in `meta/recipes-core/images/` that produces the smallest bootable Linux image: kernel, BusyBox, and little else.

### What you will see

BitBake prints a progress summary as it works through tasks:

```
Loading cache: 100% |########################################| Time: 0:00:01
Loaded 1951 entries from dependency cache.
NOTE: Resolving any missing task queue dependencies

Build Configuration:
BB_VERSION           = "2.8.0"
BUILD_SYS            = "x86_64-linux"
NATIVELSP            = ""
TARGET_SYS           = "x86_64-poky-linux"
MACHINE              = "qemux86-64"
DISTRO               = "poky"
DISTRO_VERSION       = "5.0"
TUNE_FEATURES        = "m64 corei7"
TARGET_FPU           = ""
meta                 = "scarthgap:abc1234..."
meta-poky            = "scarthgap:abc1234..."
meta-yocto-bsp       = "scarthgap:abc1234..."

Initialising tasks: 100% |###################################| Time: 0:00:10
Sstate summary: Wanted 512 Local 0 Mirrors 0 Missed 512 Current 0 (0% match ratio)
NOTE: Executing Tasks
```

The "Sstate summary" line shows how many tasks were found in the cache. On a fresh machine, `Missed` equals `Wanted` — nothing is cached yet.

### If the build fails

- Check the error message carefully; BitBake prints the failed task and a path to a log file.
- Common first-run issues are covered in [`docs/troubleshooting.md`](../docs/troubleshooting.md).
- Missing host packages are the most frequent cause — re-run `00-setup/scripts/install-deps.sh`.

---

## Step 5 — Inspect the output

When BitBake finishes successfully it prints:

```
NOTE: Tasks Summary: Attempted 2891 tasks of which 0 didn't need to be run and all succeeded.
```

The built image files are in:

```bash
ls tmp/deploy/images/qemux86-64/
```

You will see several files. The key ones are:

| File | Purpose |
|---|---|
| `core-image-minimal-qemux86-64.rootfs.ext4` | The root filesystem image |
| `bzImage` | The Linux kernel |
| `core-image-minimal-qemux86-64.qemuboot.conf` | `runqemu` configuration |

---

## Understanding what was built

`core-image-minimal` contains:

- Linux kernel (version defined by the BSP layer for `qemux86-64`)
- BusyBox — provides a shell (`sh`), `ls`, `cat`, `ps`, and ~300 other Unix utilities in a single binary
- udev — device manager
- systemd or SysVinit (depending on Poky defaults for the release)
- No package manager, no SSH, no extras

This minimal image is intentionally small. In later modules you will add packages and build custom images.

---

## A note on build time

The first build is the slowest because the sstate-cache is empty. BitBake compiles the entire toolchain (binutils, GCC, glibc), then cross-compiles every package. Subsequent builds reuse cached task outputs — rebuilding `core-image-minimal` after a clean first build typically takes under 5 minutes.

Do not interrupt the build mid-way if you can avoid it. If you must stop it, press `Ctrl-C` once and wait for BitBake to exit cleanly. A hard kill can corrupt the sstate-cache.

---

## Next Steps

You have a built image sitting in `tmp/deploy/images/qemux86-64/`. Now boot it:

➡ [`03-booting-with-qemu.md`](03-booting-with-qemu.md)
