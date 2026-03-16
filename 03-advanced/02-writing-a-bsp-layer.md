# Writing a BSP Layer

🔴 **Advanced**

In this module you create a BSP layer called `meta-bsp-tutorial` with a custom QEMU machine definition. By the end you will be able to run `MACHINE=tutorial-qemux86-64 bitbake core-image-minimal` and boot the resulting image.

---

## Step 1 — Create the layer skeleton

```bash
cd ~/yocto
source poky/oe-init-build-env build

bitbake-layers create-layer ../meta-bsp-tutorial
cd ../meta-bsp-tutorial
```

Create the directories a BSP layer needs:

```bash
mkdir -p conf/machine
mkdir -p recipes-kernel/linux
mkdir -p recipes-bsp/grub
```

---

## Step 2 — Update layer.conf

The generated `conf/layer.conf` needs a few additions for a BSP layer:

```bash
cat > conf/layer.conf << 'EOF'
# We have a conf and classes directory, add to BBPATH
BBPATH .= ":${LAYERDIR}"

# We have recipes-* directories, add to BBFILES
BBFILES += "${LAYERDIR}/recipes-*/*/*.bb \
            ${LAYERDIR}/recipes-*/*/*.bbappend"

BBFILE_COLLECTIONS += "bsp-tutorial"
BBFILE_PATTERN_bsp-tutorial = "^${LAYERDIR}/"
BBFILE_PRIORITY_bsp-tutorial = "7"

LAYERDEPENDS_bsp-tutorial = "core"
LAYERSERIES_COMPAT_bsp-tutorial = "scarthgap"

# Machine-specific configuration files
BBFILES_DYNAMIC += " \
    core:${LAYERDIR}/recipes-core/*/*/*.bbappend \
    "
EOF
```

`LAYERDEPENDS_bsp-tutorial = "core"` declares that this BSP layer requires OE-Core (`meta`). BitBake checks this and warns if the dependency is missing.

---

## Step 3 — Write the machine definition

```bash
cat > conf/machine/tutorial-qemux86-64.conf << 'EOF'
#@TYPE: Machine
#@NAME: Tutorial QEMU x86-64
#@DESCRIPTION: Custom QEMU x86-64 machine for the yocto-on-pc tutorial.
#              Extends the standard qemux86-64 with explicit QB_* settings.

# ── Inherit the standard qemux86-64 tune and include files ──────────────────
# Reuse x86-64 architecture tuning rather than duplicating it
require conf/machine/include/x86/tune-corei7.inc
require conf/machine/include/qemuboot-x86.inc

# ── Kernel ──────────────────────────────────────────────────────────────────
PREFERRED_PROVIDER_virtual/kernel = "linux-yocto"
PREFERRED_VERSION_linux-yocto = "6.6%"

KERNEL_IMAGETYPE = "bzImage"

# Extra kernel command-line arguments appended to the bootloader config
KERNEL_EXTRA_ARGS = ""

# ── Image ───────────────────────────────────────────────────────────────────
IMAGE_FSTYPES = "ext4 wic"
WKS_FILE = "qemux86-64.wks.in"

# ── Console ─────────────────────────────────────────────────────────────────
SERIAL_CONSOLES = "115200;ttyS0"
SERIAL_CONSOLES_CHECK = "${SERIAL_CONSOLES}"

# ── Machine features ─────────────────────────────────────────────────────────
# Start from qemux86-64 baseline: x86 pci usbhost keyboard screen
MACHINE_FEATURES = "x86 pci usbhost keyboard screen rtc"

# ── QEMU runtime configuration ───────────────────────────────────────────────
QB_SYSTEM_NAME = "qemu-system-x86_64"
QB_MACHINE = "-machine q35"
QB_CPU = "-cpu IvyBridge"
QB_CPU_KVM = "-cpu host -enable-kvm"
QB_KERNEL_CMDLINE_APPEND = "console=ttyS0,115200n8 root=/dev/vda rw"
QB_MEM = "-m 512"
QB_NETWORK_DEVICE = "-device virtio-net-pci,netdev=net0,mac=@MAC@"
QB_ROOTFS_OPT = "-drive id=disk0,file=@ROOTFS@,if=none,format=raw \
                 -device virtio-blk-pci,drive=disk0"
QB_OPT_APPEND = "-usb -device usb-tablet"
QB_DEFAULT_KERNEL = "bzImage"
QB_DEFAULT_FSTYPE = "ext4"
EOF
```

### What is different from qemux86-64

- `rtc` added to `MACHINE_FEATURES` — enables the real-time clock module in the kernel config
- `QB_MACHINE = "-machine q35"` — uses the Q35 chipset (more modern than i440FX)
- `QB_CPU = "-cpu IvyBridge"` — explicit CPU model instead of the QEMU default
- `QB_ROOTFS_OPT` uses `virtio-blk-pci` — paravirtualised disk for better I/O performance

---

## Step 4 — Add a kernel .bbappend

Even without modifying anything yet, add the `.bbappend` skeleton so you have a place to add kernel config fragments in the next module:

```bash
cat > recipes-kernel/linux/linux-yocto_%.bbappend << 'EOF'
# BSP-specific kernel configuration for tutorial-qemux86-64
# This file is intentionally minimal — kernel fragments are added in
# 04-kernel-fragments.md

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Only apply this bbappend when building for our machine
COMPATIBLE_MACHINE = "tutorial-qemux86-64"
EOF
```

`COMPATIBLE_MACHINE` is a regular expression matched against `MACHINE`. Setting it prevents this `.bbappend` from affecting other machines in the build.

---

## Step 5 — Register the layer and switch machines

```bash
cd ~/yocto/build

# Add the BSP layer
bitbake-layers add-layer ../meta-bsp-tutorial

# Verify it appears
bitbake-layers show-layers
```

```
layer                 path                                           priority
===========================================================================
meta                  /home/you/yocto/poky/meta                     5
meta-poky             /home/you/yocto/poky/meta-poky                6
meta-yocto-bsp        /home/you/yocto/poky/meta-yocto-bsp           6
meta-mylayer          /home/you/yocto/meta-mylayer                  6
meta-bsp-tutorial     /home/you/yocto/meta-bsp-tutorial             7
```

Switch the build to your new machine in `local.conf`:

```conf
MACHINE = "tutorial-qemux86-64"
```

---

## Step 6 — Build and boot

```bash
bitbake core-image-minimal
# With a warm sstate-cache this takes only a few minutes —
# most artefacts are reused, only machine-specific items are rebuilt
```

```bash
runqemu tutorial-qemux86-64 core-image-minimal nographic
```

Inside the guest:

```bash
cat /etc/hostname
# tutorial-qemux86-64  (set from MACHINE by default)

dmesg | grep "virtio"
# [    0.8xx] virtio-blk ...   ← confirms virtio disk is in use
```

---

## Troubleshooting

**`ERROR: No recipes available for: virtual/kernel`**

The `qemuboot-x86.inc` file from `meta-yocto-bsp` may not be on the include path. Verify `meta-yocto-bsp` is in `bblayers.conf`.

**`WARNING: COMPATIBLE_MACHINE … is not compatible`**

A recipe you are trying to build has `COMPATIBLE_MACHINE` set and does not match `tutorial-qemux86-64`. Either update the recipe's `COMPATIBLE_MACHINE` or use the correct machine name.

**`runqemu` cannot find the image**

`runqemu` looks for `<image>-<machine>.qemuboot.conf`. If the machine name in your `.conf` file does not match what you pass to `runqemu`, it will not find the image. Ensure consistency.

---

## Next Steps

Your BSP layer is registered and builds successfully. Now configure the kernel for your machine:

➡ [`03-kernel-configuration.md`](03-kernel-configuration.md)
