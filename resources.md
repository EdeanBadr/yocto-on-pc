# Resources

Curated links for learning more about the Yocto Project, OpenEmbedded, and embedded Linux in general. All links verified against the **Scarthgap (5.0 LTS)** release.

---

## Official documentation

| Resource | URL | What it covers |
|---|---|---|
| Yocto Project Quick Build | https://docs.yoctoproject.org/5.0/brief-yoctoprojectqs/index.html | Getting to a first build in under an hour |
| Yocto Project Overview and Concepts Manual | https://docs.yoctoproject.org/5.0/overview-manual/index.html | Architecture, terminology, workflow |
| BitBake User Manual | https://docs.yoctoproject.org/bitbake/2.8/bitbake-user-manual/index.html | Full BitBake reference: syntax, tasks, fetchers |
| Yocto Project Reference Manual | https://docs.yoctoproject.org/5.0/ref-manual/index.html | All variables, classes, and system requirements |
| Yocto Project Development Tasks Manual | https://docs.yoctoproject.org/5.0/dev-manual/index.html | How-to guides: layers, recipes, images, SDK |
| Yocto Project Linux Kernel Development Manual | https://docs.yoctoproject.org/5.0/kernel-dev/index.html | Kernel configuration, fragments, out-of-tree modules |
| Yocto Project Board Support Package (BSP) Developer's Guide | https://docs.yoctoproject.org/5.0/bsp-guide/index.html | Writing BSP layers, machine definitions |

---

## Layer index

| Resource | URL |
|---|---|
| OpenEmbedded Layer Index | https://layers.openembedded.org |

Search by layer name or recipe name. Filter by **scarthgap** to find compatible layers. The layer index also shows which recipes are available in which layers, and whether a layer passes Yocto's automated compatibility tests.

---

## Source repositories

| Repository | URL | Branch |
|---|---|---|
| Poky (BitBake + OE-Core + Poky distro) | git://git.yoctoproject.org/poky | `scarthgap` |
| meta-openembedded | https://github.com/openembedded/meta-openembedded | `scarthgap` |
| linux-yocto kernel | git://git.yoctoproject.org/linux-yocto | `v6.6/standard/base` |
| BitBake | git://git.openembedded.org/bitbake | `2.8` |

---

## Community

| Channel | Details |
|---|---|
| Mailing list | `yocto@lists.yoctoproject.org` — general discussion and questions |
| IRC | `#yocto` on [Libera.Chat](https://libera.chat) — real-time help |
| Bug tracker | https://bugzilla.yoctoproject.org |
| Weekly calls | Public technical calls listed on https://wiki.yoctoproject.org/wiki/Yocto_Project_Weekly_Call |

When asking for help, include: your Yocto release (`scarthgap`), the failing task and recipe name, and the full error from the BitBake log file (`build/tmp/work/.../temp/log.do_<task>`).

---

## Books

| Title | Author(s) | Notes |
|---|---|---|
| *Embedded Linux Development Using Yocto Project* (3rd ed.) | Otavio Salvador, Daiane Angolini | Covers Kirkstone; concepts remain valid for Scarthgap |
| *Embedded Linux Systems with the Yocto Project* | Rudolf Streif | Older but strong on architecture and theory |
| *Mastering Embedded Linux Programming* (3rd ed.) | Frank Vasquez, Chris Simmonds | Broad embedded Linux book; good Yocto chapters |

---

## Related tools and projects

| Tool / Project | URL | Relationship to Yocto |
|---|---|---|
| Buildroot | https://buildroot.org | Alternative embedded Linux build system; simpler, less flexible |
| CROPS (Containers for Yocto Project) | https://github.com/crops/poky-container | Run Yocto builds in Docker containers |
| Kas | https://kas.readthedocs.io | YAML-based tool for managing Yocto layer configurations |
| toaster | https://docs.yoctoproject.org/5.0/toaster-manual/ | Web UI for monitoring and analysing BitBake builds |
| QEMU | https://www.qemu.org | The emulator used throughout this repository |
| OpenEmbedded | https://www.openembedded.org | The broader ecosystem Yocto is built on |

---

## Cheat sheets

### Useful BitBake one-liners

```bash
# Show all layers and their priorities
bitbake-layers show-layers

# Find which layer provides a recipe
bitbake-layers show-recipes busybox

# Show all active .bbappend files
bitbake-layers show-appends

# Show resolved variable values for a recipe
bitbake -e core-image-minimal | grep "^IMAGE_INSTALL="

# List all tasks for a recipe
bitbake -c listtasks core-image-minimal

# Run a specific task
bitbake curl -c do_configure

# Force a task to re-run (ignore sstate)
bitbake curl -c compile --no-setscene

# Clean a recipe's work directory and sstate
bitbake curl -c cleansstate

# Clean everything for a recipe
bitbake curl -c cleanall

# Find which recipe installed a file (requires a completed build)
oe-pkgdata-util find-path /usr/bin/curl
```

### runqemu flags

```bash
# Basic boot, no graphics
runqemu qemux86-64 core-image-minimal nographic

# User-mode networking (no tap, no root required)
runqemu qemux86-64 core-image-minimal nographic slirp

# Forward host port 2222 to guest port 22
runqemu qemux86-64 core-image-minimal nographic slirp \
    QB_SLIRP_OPT="-hostfwd tcp::2222-:22"

# Specify RAM
runqemu qemux86-64 core-image-minimal nographic \
    QB_MEM="-m 1024"

# Boot a specific kernel and rootfs
runqemu qemux86-64 path/to/bzImage path/to/rootfs.ext4 nographic
```
