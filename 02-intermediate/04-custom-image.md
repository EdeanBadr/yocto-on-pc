# Creating a Custom Image

🟡 **Intermediate**

Adding packages via `IMAGE_INSTALL:append` in `local.conf` is fine for experiments, but it is not reproducible — the settings live in your build directory and are not part of your layer. A **custom image recipe** defines the image's complete contents declaratively inside your layer, making it version-controlled and shareable.

---

## Why a custom image recipe?

- **Reproducibility** — the image definition is in your layer, tracked in git, and produces the same result on any machine.
- **Clarity** — a reader can open one file and see exactly what is in the image.
- **Composability** — you can inherit from standard image classes and extend them cleanly.
- **CI integration** — build servers can build your named image (`bitbake my-product-image`) without any local configuration.

---

## Step 1 — Create the image recipe file

Image recipes live in `recipes-core/images/` by convention (though any `recipes-*/` subdirectory works).

```bash
mkdir -p ~/yocto/meta-mylayer/recipes-core/images
```

```bash
cat > ~/yocto/meta-mylayer/recipes-core/images/my-image.bb << 'EOF'
SUMMARY = "A custom product image for the Yocto tutorial"
DESCRIPTION = "Minimal image with SSH access and a custom hello application."

# Inherit the standard image class — provides do_rootfs, do_image, etc.
inherit core-image

# Base image features — these expand to package sets
IMAGE_FEATURES += "ssh-server-dropbear"

# Explicit package list
IMAGE_INSTALL = " \
    packagegroup-core-boot \
    packagegroup-base-extended \
    hello-yocto \
    python3 \
    curl \
    strace \
    "
EOF
```

### Key decisions in this recipe

**`inherit core-image`** — this class provides the `do_rootfs` and `do_image` tasks. All standard Poky images inherit it. Without it, BitBake would not know how to assemble a filesystem image from packages.

**`packagegroup-core-boot`** — installs the minimum set of packages needed to boot: init, udev, kernel modules. Always include this (or an equivalent) in any bootable image.

**`IMAGE_INSTALL =`** — note the plain assignment, not `:append`. In an image recipe you own the variable, so you set it directly rather than appending to whatever `local.conf` has.

---

## Step 2 — Build it

```bash
cd ~/yocto/build
bitbake my-image
# Takes a few minutes with a warm sstate-cache
```

The output image appears in:

```bash
ls tmp/deploy/images/qemux86-64/my-image-qemux86-64*
# my-image-qemux86-64.rootfs.ext4
# my-image-qemux86-64.qemuboot.conf
# my-image-qemux86-64.manifest
```

---

## Step 3 — Boot and verify

```bash
runqemu qemux86-64 my-image nographic
```

Inside the guest:

```bash
hello-yocto
# Hello from Yocto!

python3 --version
# Python 3.12.x

which dropbear
# /usr/sbin/dropbear
```

---

## Controlling image size

### IMAGE_ROOTFS_SIZE

Sets the minimum root filesystem size in KB:

```bitbake
IMAGE_ROOTFS_SIZE = "65536"   # 64 MB minimum
```

### IMAGE_ROOTFS_EXTRA_SPACE

Adds extra free space (in KB) on top of the installed package footprint:

```bitbake
IMAGE_ROOTFS_EXTRA_SPACE = "524288"   # 512 MB extra
```

### IMAGE_OVERHEAD_FACTOR

Multiplier applied to the installed size to leave overhead:

```bitbake
IMAGE_OVERHEAD_FACTOR = "1.3"   # 30% extra space
```

---

## Image types (formats)

By default, Poky produces `.ext4` and `.tar.bz2` images. You can request additional formats:

```bitbake
IMAGE_FSTYPES = "ext4 wic.gz tar.bz2"
```

For QEMU, `ext4` is sufficient. The `.wic` format creates a full disk image with a partition table — useful for writing to a real storage device.

---

## Inheriting from an existing image

Instead of starting from `core-image`, you can inherit from a named image to get everything it provides and add more:

```bitbake
# my-image-dev.bb — extends my-image with development tools
require my-image.bb

SUMMARY = "Development variant of my-image with debug tools"

IMAGE_INSTALL:append = " \
    gdb \
    gdbserver \
    strace \
    tcpdump \
    "

IMAGE_FEATURES += "debug-tweaks"
```

`require` is like `include` — BitBake errors if the file is not found. This ensures `my-image-dev.bb` always builds on top of a specific base.

---

## Package groups in your layer

For larger projects, define package groups to organise the package list:

```bash
mkdir -p ~/yocto/meta-mylayer/recipes-core/packagegroups
```

```bitbake
# packagegroup-myproduct-base.bb
SUMMARY = "Core packages for my product"

inherit packagegroup

RDEPENDS:${PN} = " \
    hello-yocto \
    curl \
    python3 \
    "
```

Then reference it from the image recipe:

```bitbake
IMAGE_INSTALL = " \
    packagegroup-core-boot \
    packagegroup-myproduct-base \
    "
```

This keeps the image recipe clean and lets you reuse the package group across multiple image variants.

---

## Removing packages from an inherited image

If you inherit from `core-image-minimal` and want to exclude a package it includes:

```bitbake
IMAGE_INSTALL:remove = " package-to-exclude"
```

The `:remove` operator removes a value from the list without knowing its position.

---

## DISTRO vs IMAGE — what controls what?

| Concern | Set by | Variable |
|---|---|---|
| Which packages are in the image | Image recipe | `IMAGE_INSTALL`, `IMAGE_FEATURES` |
| Which init system (systemd vs SysVinit) | Distro or image | `DISTRO_FEATURES`, `IMAGE_FEATURES` |
| Which C library (glibc vs musl) | Distro | `TCLIBC` |
| Compiler flags, optimisation level | Distro | `FULL_OPTIMIZATION`, `DEBUG_FLAGS` |
| Target architecture | Machine | `MACHINE`, `TUNE_FEATURES` |

Image recipes control content. Distro configuration controls policy. Machine configuration controls the hardware target.

---

## Next Steps

You have a custom image recipe in your layer. Now learn to use `devtool` to make iterative changes to recipes without running full rebuilds:

➡ [`05-devtool-workflow.md`](05-devtool-workflow.md)
