# Custom Machine: Putting It All Together

🔴 **Advanced**

This is the capstone module. You consolidate everything from the advanced track: a BSP layer, a custom machine definition, a kernel with targeted configuration fragments, a custom image, and a complete `runqemu` boot. By the end you have a reproducible, version-controlled embedded Linux system built entirely in software.

---

## What you are building

| Component | Description |
|---|---|
| Machine | `tutorial-qemux86-64` — Q35 QEMU target, virtio disk, 512 MB RAM |
| Kernel | `linux-yocto 6.6.x` with virtio built in |
| Image | `tutorial-image` — minimal + SSH + your hello-yocto app |
| Layer stack | `meta` + `meta-poky` + `meta-yocto-bsp` + `meta-mylayer` + `meta-bsp-tutorial` |

---

## Prerequisites checklist

Confirm the following are in place before starting:

```bash
# Layers registered
bitbake-layers show-layers
# meta, meta-poky, meta-yocto-bsp, meta-mylayer, meta-bsp-tutorial all listed

# Machine set in local.conf
grep MACHINE build/conf/local.conf
# MACHINE = "tutorial-qemux86-64"

# BSP layer file structure
ls ~/yocto/meta-bsp-tutorial/
# conf/  recipes-kernel/

ls ~/yocto/meta-bsp-tutorial/conf/machine/
# tutorial-qemux86-64.conf

ls ~/yocto/meta-bsp-tutorial/recipes-kernel/linux/linux-yocto/
# virtio.cfg  (debug.cfg optional)
```

---

## Step 1 — Create the tutorial image recipe

Add an image recipe to `meta-bsp-tutorial` that is specific to this machine:

```bash
mkdir -p ~/yocto/meta-bsp-tutorial/recipes-core/images
```

```bash
cat > ~/yocto/meta-bsp-tutorial/recipes-core/images/tutorial-image.bb << 'EOF'
SUMMARY = "Tutorial image: minimal headless system with SSH and hello-yocto"
DESCRIPTION = "Used in the yocto-on-pc advanced tutorial to demonstrate a \
complete custom machine + custom image stack."

inherit core-image

# This image is only valid for the tutorial machine
COMPATIBLE_MACHINE = "tutorial-qemux86-64"

IMAGE_FEATURES += "ssh-server-dropbear"

IMAGE_INSTALL = " \
    packagegroup-core-boot \
    dropbear \
    hello-yocto \
    python3 \
    curl \
    strace \
    procps \
    util-linux \
    "

# 256 MB root filesystem
IMAGE_ROOTFS_SIZE = "262144"
IMAGE_ROOTFS_EXTRA_SPACE = "51200"

# Produce ext4 (for QEMU) and a wic disk image (for reference)
IMAGE_FSTYPES = "ext4 wic"
EOF
```

---

## Step 2 — Verify the full layer stack

```bash
cd ~/yocto/build
bitbake-layers show-layers
```

Expected output:

```
layer                 path                                           priority
===========================================================================
meta                  .../poky/meta                                  5
meta-poky             .../poky/meta-poky                             6
meta-yocto-bsp        .../poky/meta-yocto-bsp                        6
meta-mylayer          .../meta-mylayer                               6
meta-bsp-tutorial     .../meta-bsp-tutorial                          7
```

Check for parse errors:

```bash
bitbake-layers show-recipes 2>&1 | grep -i error
# Should be empty
```

---

## Step 3 — Parse and inspect the machine variables

```bash
bitbake -e tutorial-image | grep -E "^(MACHINE|KERNEL_IMAGETYPE|QB_|IMAGE_FSTYPES|MACHINE_FEATURES)=" | sort
```

This shows the resolved values for all the key variables after all layers, `.bbappend` files, and `local.conf` overrides have been applied. Use this to confirm your machine definition is being read correctly.

---

## Step 4 — Build

```bash
# Full build — 5–20 minutes with a warm sstate-cache
bitbake tutorial-image
```

Monitor build progress. BitBake will print a summary at the end:

```
NOTE: Tasks Summary: Attempted XXXX tasks of which YYY didn't need to be run and all succeeded.
```

Check the deploy directory:

```bash
ls tmp/deploy/images/tutorial-qemux86-64/
# tutorial-image-tutorial-qemux86-64.rootfs.ext4
# tutorial-image-tutorial-qemux86-64.wic
# tutorial-image-tutorial-qemux86-64.qemuboot.conf
# tutorial-image-tutorial-qemux86-64.manifest
# bzImage--6.6.x-tutorial-qemux86-64.bin
# bzImage -> bzImage--6.6.x-...
```

---

## Step 5 — Boot

```bash
runqemu tutorial-qemux86-64 tutorial-image nographic
```

`runqemu` reads `tutorial-image-tutorial-qemux86-64.qemuboot.conf` to construct the QEMU command line. The actual command it runs looks like:

```bash
qemu-system-x86_64 \
    -machine q35 \
    -cpu IvyBridge \
    -m 512 \
    -kernel bzImage \
    -drive id=disk0,file=tutorial-image-tutorial-qemux86-64.rootfs.ext4,if=none,format=raw \
    -device virtio-blk-pci,drive=disk0 \
    -device virtio-net-pci,netdev=net0,mac=52:54:00:12:34:56 \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -append "root=/dev/vda console=ttyS0,115200n8 ..." \
    -nographic
```

---

## Step 6 — Validate

Inside the QEMU guest:

```bash
# Machine identity
cat /etc/hostname
# tutorial-qemux86-64

uname -r
# 6.6.x-yocto-standard  (or 6.6.x-tutorial if you set LINUX_VERSION_EXTENSION)

# Virtio disk confirmed
dmesg | grep virtio
# [    0.5xx] virtio-blk virtio0: [vda] ...

# Kernel config: virtio built in
zcat /proc/config.gz | grep "CONFIG_VIRTIO_BLK"
# CONFIG_VIRTIO_BLK=y

# Custom app present
hello-yocto
# Hello from Yocto!

# SSH available
ps | grep dropbear
# dropbear ...

# Python available
python3 -c "print('Python works')"
# Python works
```

---

## Step 7 — SSH from the host

```bash
# From the host, dropbear listens on the guest at 192.168.7.2:22
ssh root@192.168.7.2
# or if using slirp with hostfwd:
ssh root@localhost -p 2222
```

---

## Reproducing the build on another machine

Everything needed to reproduce this build is in your layers:

```
meta-mylayer/         ← hello-yocto recipe + custom image
meta-bsp-tutorial/    ← machine definition + kernel fragments
```

On a fresh host:

```bash
git clone -b scarthgap git://git.yoctoproject.org/poky.git ~/yocto/poky
# clone meta-mylayer and meta-bsp-tutorial from your own git repos
source ~/yocto/poky/oe-init-build-env ~/yocto/build
bitbake-layers add-layer ~/yocto/meta-mylayer
bitbake-layers add-layer ~/yocto/meta-bsp-tutorial
echo 'MACHINE = "tutorial-qemux86-64"' >> conf/local.conf
bitbake tutorial-image
```

That is the reproducibility guarantee Yocto provides: given the same layer commits and `local.conf`, the build produces a bit-for-bit identical image.

---

## What to explore next

- **SDK generation** — `bitbake tutorial-image -c populate_sdk` creates a standalone cross-compilation toolchain you can distribute to application developers.
- **eSDK** — `bitbake tutorial-image -c populate_sdk_ext` creates an extensible SDK that includes `devtool`, allowing developers to work on recipes without a full Yocto setup.
- **Real hardware** — Replace `tutorial-qemux86-64.conf` with a real board's machine definition and the same layer + image structure works on physical hardware.
- **CI integration** — Run `bitbake tutorial-image` in a CI pipeline (GitLab CI, GitHub Actions, Jenkins) to gate merges on successful image builds.

See [`resources.md`](../resources.md) for links to further documentation and community resources.

---

## Next Steps

You have completed the advanced track. Continue with the reference materials:

➡ [`docs/glossary.md`](../docs/glossary.md) — definitions for every Yocto term used in this repository
➡ [`resources.md`](../resources.md) — official documentation, community channels, and further reading
