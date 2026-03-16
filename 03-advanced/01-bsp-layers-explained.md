# BSP Layers Explained

🔴 **Advanced**

A Board Support Package (BSP) layer is a specialised Yocto layer that describes a hardware target: its CPU architecture, bootloader, kernel configuration, and any hardware-specific drivers or firmware. Without a BSP layer, BitBake does not know how to configure the kernel or produce a bootable image for your target.

---

## BSP layer vs software layer

| Concern | Software layer | BSP layer |
|---|---|---|
| Primary content | Application recipes, library recipes | Machine definitions, kernel config, bootloader recipes |
| Naming convention | `meta-<product>`, `meta-<feature>` | `meta-<vendor>` or `meta-<board>` |
| `MACHINE` definitions | None (or board-agnostic) | One or more `.conf` files in `conf/machine/` |
| Kernel customisation | Generally none | `linux-yocto` `.bbappend`, kernel fragments |
| Bootloader | Generally none | `u-boot`, `grub`, or platform bootloader recipes |

A single layer can be both a software layer and a BSP layer, but separating them is good practice — it keeps hardware-specific content isolated and makes porting to a new board easier.

---

## What lives in a BSP layer

```
meta-vendor/
├── conf/
│   ├── layer.conf
│   └── machine/
│       └── myboard.conf        ← machine definition
├── recipes-bsp/
│   ├── bootloader/
│   │   └── u-boot_%.bbappend   ← board-specific U-Boot config
│   └── firmware/
│       └── vendor-firmware_1.0.bb
├── recipes-kernel/
│   └── linux/
│       ├── linux-yocto_%.bbappend  ← kernel config + patches
│       └── linux-yocto/
│           ├── myboard.cfg         ← kernel config fragment
│           └── 0001-fix-uart.patch
└── README
```

---

## The machine definition file

`conf/machine/myboard.conf` is the central file of a BSP. It sets variables that BitBake uses throughout the build:

```conf
#@TYPE: Machine
#@NAME: My Tutorial Board
#@DESCRIPTION: Machine configuration for the tutorial QEMU target

# ── Architecture ────────────────────────────────────────────────────────────
# The tune file sets CPU-specific compiler flags (ABI, ISA extensions)
require conf/machine/include/x86/tune-corei7.inc

# ── Kernel ──────────────────────────────────────────────────────────────────
PREFERRED_PROVIDER_virtual/kernel = "linux-yocto"
PREFERRED_VERSION_linux-yocto = "6.6%"

KERNEL_IMAGETYPE = "bzImage"

# ── Bootloader ───────────────────────────────────────────────────────────────
PREFERRED_PROVIDER_virtual/bootloader = "grub-efi"

# ── Image types ─────────────────────────────────────────────────────────────
IMAGE_FSTYPES = "ext4 wic"

# ── Serial console ───────────────────────────────────────────────────────────
SERIAL_CONSOLES = "115200;ttyS0"

# ── Machine features ─────────────────────────────────────────────────────────
# Features gate which recipes are built and which kernel options are enabled
MACHINE_FEATURES = "x86 pci usbhost keyboard screen alsa"

# ── QEMU options (used by runqemu) ───────────────────────────────────────────
QB_SYSTEM_NAME = "qemu-system-x86_64"
QB_MACHINE = "-machine q35"
QB_CPU = "-cpu IvyBridge"
QB_KERNEL_CMDLINE_APPEND = "console=ttyS0,115200n8"
QB_MEM = "-m 512"
```

### Key variables

| Variable | Purpose |
|---|---|
| `PREFERRED_PROVIDER_virtual/kernel` | Which kernel recipe to use (`linux-yocto`, `linux-ti-staging`, etc.) |
| `PREFERRED_VERSION_linux-yocto` | Pin to a specific kernel version series |
| `KERNEL_IMAGETYPE` | Output format: `bzImage` (x86), `Image` (AArch64), `uImage` (ARM32) |
| `MACHINE_FEATURES` | Feature flags that control recipe behaviour across the build |
| `SERIAL_CONSOLES` | Baud rate and device for the serial console |
| `QB_*` | Variables consumed by `runqemu` to construct the QEMU command line |

---

## MACHINE_FEATURES

`MACHINE_FEATURES` is a space-separated list of hardware capabilities. Recipes check this list to decide which code paths to enable. For example:

- `wifi` — enables wireless recipes
- `bluetooth` — pulls in BlueZ
- `x86` — enables x86-specific kernel modules
- `usbhost` — enables USB host controller support
- `screen` — enables display-related packages
- `alsa` — enables ALSA sound subsystem

```conf
MACHINE_FEATURES = "x86 pci usbhost keyboard screen"
```

Removing `screen` from this list tells recipes that the machine has no display — they will skip installing framebuffer or display server components.

---

## virtual/kernel and virtual/bootloader

`virtual/kernel` and `virtual/bootloader` are **virtual providers** — abstract names that decouple the machine definition from a specific recipe name. This lets you switch the kernel recipe just by changing `PREFERRED_PROVIDER_virtual/kernel` in the machine file, without modifying any image or software recipe.

```conf
# Use mainline linux-yocto
PREFERRED_PROVIDER_virtual/kernel = "linux-yocto"

# Or switch to a vendor kernel
PREFERRED_PROVIDER_virtual/kernel = "linux-myvendor"
```

Both recipes must provide `virtual/kernel` in their recipe by declaring:

```bitbake
PROVIDES += "virtual/kernel"
```

---

## How meta-yocto-bsp implements QEMU targets

The `meta-yocto-bsp` layer (inside Poky) provides the machine definitions for all the standard `qemu*` targets. Look at the existing `qemux86-64` definition as a reference:

```bash
cat ~/yocto/poky/meta-yocto-bsp/conf/machine/qemux86-64.conf
```

You will see it uses the same variables described above. In the next module you will create your own machine definition that extends or replaces this one.

---

## Checking BSP layer compatibility

Before adding a BSP layer from a third party, verify it declares Scarthgap compatibility:

```bash
grep LAYERSERIES_COMPAT ~/yocto/meta-vendor/conf/layer.conf
# LAYERSERIES_COMPAT_vendor = "scarthgap"
```

If the layer only lists older releases (`kirkstone`, `dunfell`), it may still work but recipes are more likely to need patching. Always test.

---

## Next Steps

You understand what a BSP layer contains and why each piece exists. Now write one:

➡ [`02-writing-a-bsp-layer.md`](02-writing-a-bsp-layer.md)
