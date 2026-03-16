# Kernel Configuration

🔴 **Advanced**

Yocto builds the Linux kernel from source using the `linux-yocto` recipe. Unlike a typical distribution kernel, Yocto's kernel is configured using a layered system of **configuration fragments** — small `.cfg` files that each enable or disable a handful of Kconfig options. This module explains how the kernel configuration system works before you start writing fragments in the next module.

---

## The linux-yocto recipe

`linux-yocto` is the primary kernel recipe in OE-Core. It is not a fork — it fetches the upstream Linux kernel source and applies Yocto-specific patches and configuration on top.

```bash
# Find the recipe
find ~/yocto/poky -name "linux-yocto_*.bb" | head -5
# ~/yocto/poky/meta/recipes-kernel/linux/linux-yocto_6.6.bb
```

Key variables in the recipe:

```bitbake
SRC_URI = "git://git.yoctoproject.org/linux-yocto.git;name=machine;..."
SRCREV_machine = "..."    # pinned commit for the machine branch
SRCREV_meta    = "..."    # pinned commit for the metadata branch

LINUX_VERSION = "6.6.x"
LINUX_KERNEL_TYPE = "standard"   # standard, tiny, preempt-rt
```

`linux-yocto` uses a **two-repository model**:
- `machine` branch — the actual kernel source
- `meta` branch — Yocto kernel metadata: feature descriptions, config fragments, patches

You interact with this system through fragments and `.bbappend` files, not by modifying the recipe directly.

---

## How the kernel config is assembled

BitBake assembles the final `.config` from multiple sources, applied in order:

```
1. BSP defconfig (from machine .bbappend or KBUILD_DEFCONFIG)
         ↓
2. Yocto kernel features (from SRC_URI += "features/...")
         ↓
3. User config fragments (from SRC_URI += "file://myfrag.cfg")
         ↓
4. Result: .config used by make menuconfig / make bzImage
```

Fragments are additive. A fragment that sets `CONFIG_FOO=y` wins over an earlier fragment that left it unset. A fragment that sets `# CONFIG_FOO is not set` wins over an earlier `CONFIG_FOO=y`.

---

## Inspecting the current kernel config

After a successful build, the final assembled `.config` is in the kernel work directory:

```bash
# Find the kernel build directory
find ~/yocto/build/tmp -name ".config" -path "*/linux-yocto*" | head -1
# ~/yocto/build/tmp/work/x86_64-poky-linux/linux-yocto/6.6.x.../linux-qemux86-64-standard-build/.config
```

Search it for a specific option:

```bash
grep CONFIG_VIRTIO_BLK ~/yocto/build/tmp/work/x86_64-poky-linux/linux-yocto/6.6.*/linux-*/. config
# CONFIG_VIRTIO_BLK=y
```

---

## menuconfig — interactive kernel configuration

You can launch the familiar `make menuconfig` interface through BitBake:

```bash
bitbake linux-yocto -c menuconfig
```

BitBake prepares the source and runs `menuconfig` in the kernel source tree. Save and exit normally (Save → Exit).

After saving, BitBake generates a **configuration fragment** containing only the options you changed, placed at:

```
build/tmp/work/.../linux-yocto/.../fragment.cfg
```

Copy that fragment into your BSP layer:

```bash
cp build/tmp/work/*/linux-yocto/*/fragment.cfg \
   ~/yocto/meta-bsp-tutorial/recipes-kernel/linux/linux-yocto/tutorial.cfg
```

You will then add it to `SRC_URI` in your `.bbappend` — covered in the next module.

---

## diffconfig — auditing differences

After running `menuconfig` and rebuilding, you can compare the running config against the previous one:

```bash
bitbake linux-yocto -c diffconfig
```

This generates a minimal fragment showing only what changed:

```
# CONFIG_SOUND was set to y, now not set
# CONFIG_USB_AUDIO was set to y, now not set
CONFIG_VIRTIO_SOUND=y
```

This is also useful when debugging — run `diffconfig` after adding your fragment to verify it was applied as expected.

---

## LINUX_KERNEL_TYPE

The `linux-yocto` recipe supports three kernel types, selected by `LINUX_KERNEL_TYPE` in your machine `.conf` or `.bbappend`:

| Type | Use case |
|---|---|
| `standard` | General purpose, most drivers enabled. Default for QEMU targets. |
| `tiny` | Minimal config, smallest possible kernel binary. Used on resource-constrained targets. |
| `preempt-rt` | Full preemption patch set applied. Used for real-time applications. |

```conf
# In your machine .conf:
LINUX_KERNEL_TYPE = "standard"
```

---

## Kernel version pinning

Each `linux-yocto_6.6.bb` recipe pins to a specific commit via `SRCREV_machine`. If you need to update to a newer 6.6.x point release, override `SRCREV_machine` in your `.bbappend`:

```bitbake
# recipes-kernel/linux/linux-yocto_%.bbappend
SRCREV_machine:tutorial-qemux86-64 = "abc123def..."
LINUX_VERSION:tutorial-qemux86-64 = "6.6.30"
LINUX_VERSION_EXTENSION:tutorial-qemux86-64 = "-tutorial"
```

`LINUX_VERSION_EXTENSION` appends a string to the kernel version string shown by `uname -r`:

```bash
uname -r
# 6.6.30-tutorial
```

---

## Checking which config options are active

`bitbake-layers` does not expose kernel config details, but you can use `bitbake` itself:

```bash
# Run the kernel config audit task — reports any missing or conflicting options
bitbake linux-yocto -c kernel_configcheck
```

This checks your fragments against the assembled config and warns about options that were requested but not applied (e.g., because a dependency is missing).

---

## Next Steps

You understand how the kernel configuration system works. Now write your own config fragment:

➡ [`04-kernel-fragments.md`](04-kernel-fragments.md)
