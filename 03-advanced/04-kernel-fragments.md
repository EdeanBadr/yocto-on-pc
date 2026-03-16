# Kernel Configuration Fragments

🔴 **Advanced**

A kernel configuration fragment is a small text file containing a subset of Kconfig options. Instead of maintaining a complete `.config` file (thousands of lines), you maintain focused fragments — one per feature or concern. This module shows you how to write, apply, and validate fragments.

---

## Fragment file format

A fragment file has the same format as a Linux `.config` file — one option per line:

```cfg
# Enable virtio paravirtualised drivers (needed for QEMU virtio-blk)
CONFIG_VIRTIO=y
CONFIG_VIRTIO_PCI=y
CONFIG_VIRTIO_BLK=y
CONFIG_VIRTIO_NET=y
CONFIG_VIRTIO_CONSOLE=y

# Disable sound (not needed on our headless QEMU target)
# CONFIG_SOUND is not set

# Enable network namespaces (needed for container workloads)
CONFIG_NET_NS=y
CONFIG_PID_NS=y
```

Rules:
- `CONFIG_FOO=y` — enable as built-in
- `CONFIG_FOO=m` — enable as loadable module
- `# CONFIG_FOO is not set` — explicitly disable
- Lines starting with `#` followed by text (not `is not set`) are comments and are ignored by Kconfig

You do not need to list every option — only the ones you want to change from the BSP baseline. The fragment is *merged* with the base config, not substituted for it.

---

## Step 1 — Create the fragment directory

```bash
mkdir -p ~/yocto/meta-bsp-tutorial/recipes-kernel/linux/linux-yocto
```

---

## Step 2 — Write a virtio fragment

For the `tutorial-qemux86-64` machine, virtio drivers ensure good I/O performance inside QEMU. Create a fragment to guarantee they are built in (not just as modules):

```bash
cat > ~/yocto/meta-bsp-tutorial/recipes-kernel/linux/linux-yocto/virtio.cfg << 'EOF'
# Virtio transport and drivers — built in for QEMU targets
CONFIG_VIRTIO=y
CONFIG_VIRTIO_PCI=y
CONFIG_VIRTIO_PCI_LEGACY=y
CONFIG_VIRTIO_BLK=y
CONFIG_VIRTIO_NET=y
CONFIG_VIRTIO_CONSOLE=y
CONFIG_VIRTIO_INPUT=y
CONFIG_HW_RANDOM_VIRTIO=y
EOF
```

---

## Step 3 — Write a debug fragment

A separate fragment for debug capabilities that you might include in development builds but exclude from production:

```bash
cat > ~/yocto/meta-bsp-tutorial/recipes-kernel/linux/linux-yocto/debug.cfg << 'EOF'
# Kernel debug options — include in dev images only
CONFIG_DEBUG_INFO=y
CONFIG_DEBUG_INFO_DWARF5=y
CONFIG_GDB_SCRIPTS=y
CONFIG_FRAME_POINTER=y
CONFIG_KGDB=y
CONFIG_KGDB_SERIAL_CONSOLE=y

# Ftrace — function tracing infrastructure
CONFIG_FTRACE=y
CONFIG_FUNCTION_TRACER=y
CONFIG_DYNAMIC_FTRACE=y
EOF
```

---

## Step 4 — Apply fragments via the .bbappend

Open (or update) the kernel `.bbappend` in your BSP layer:

```bash
cat > ~/yocto/meta-bsp-tutorial/recipes-kernel/linux/linux-yocto_%.bbappend << 'EOF'
# Kernel configuration for tutorial-qemux86-64
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

COMPATIBLE_MACHINE = "tutorial-qemux86-64"

# Always apply the virtio fragment
SRC_URI:append:tutorial-qemux86-64 = " \
    file://virtio.cfg \
    "
EOF
```

Note that `debug.cfg` is intentionally not added yet — you will add it conditionally in Step 6.

---

## Step 5 — Build and verify

```bash
cd ~/yocto/build
bitbake linux-yocto -c configure
# Sets up the source tree and runs the Kconfig merge step

# Verify the fragment was applied
grep CONFIG_VIRTIO_BLK \
    tmp/work/*/linux-yocto/*/linux-tutorial-qemux86-64-standard-build/.config
# CONFIG_VIRTIO_BLK=y
```

Run the config audit:

```bash
bitbake linux-yocto -c kernel_configcheck 2>&1 | grep -E "WARN|ERROR|fragment"
```

If an option in your fragment could not be applied (e.g., because `CONFIG_VIRTIO_PCI` depends on `CONFIG_PCI` which is disabled), `kernel_configcheck` reports it.

Then rebuild the full image:

```bash
bitbake core-image-minimal
# Only the kernel and image tasks re-run; everything else is cached
```

Boot and verify inside QEMU:

```bash
runqemu tutorial-qemux86-64 core-image-minimal nographic

# Inside guest:
cat /proc/config.gz | gunzip | grep CONFIG_VIRTIO_BLK
# CONFIG_VIRTIO_BLK=y

dmesg | grep virtio
# [    0.5xx] virtio-blk virtio0: [vda] 524288 512-byte logical blocks
```

---

## Step 6 — Conditional fragments

Include `debug.cfg` only when an image-level variable requests it:

```bitbake
# In linux-yocto_%.bbappend — append to the existing content

# Include debug fragment when DEBUG_BUILD is set
SRC_URI:append:tutorial-qemux86-64 = " \
    ${@bb.utils.contains('DEBUG_BUILD', '1', 'file://debug.cfg', '', d)} \
    "
```

`bb.utils.contains` is a BitBake Python inline expression. It evaluates to `'file://debug.cfg'` if `DEBUG_BUILD = "1"` is set (in `local.conf` or on the command line), and to `''` otherwise.

Enable it for a one-off build:

```bash
DEBUG_BUILD=1 bitbake core-image-minimal
```

Or permanently in `local.conf`:

```conf
DEBUG_BUILD = "1"
```

---

## Generating a fragment from menuconfig changes

If you made changes via `bitbake linux-yocto -c menuconfig` and want to capture them as a fragment:

```bash
bitbake linux-yocto -c diffconfig
# Writes a fragment to:
# tmp/work/*/linux-yocto/*/fragment.cfg
```

Review it:

```bash
cat tmp/work/*/linux-yocto/*/fragment.cfg
```

If it looks right, copy it to your layer:

```bash
cp tmp/work/*/linux-yocto/*/fragment.cfg \
   ~/yocto/meta-bsp-tutorial/recipes-kernel/linux/linux-yocto/my-changes.cfg
```

Then add `file://my-changes.cfg` to `SRC_URI` in the `.bbappend`.

---

## Fragment naming conventions

| Convention | Purpose |
|---|---|
| `virtio.cfg` | Driver/subsystem name — what the fragment enables |
| `debug.cfg` | Purpose — debug vs production |
| `<machine>.cfg` | Machine-specific baseline |
| `disable-sound.cfg` | Explicit about disabling something |

Keep fragments focused. A fragment that enables 50 unrelated options is hard to review and debug. Prefer several small fragments over one large one.

---

## Next Steps

You can write and apply kernel fragments. Pull everything together by building a fully custom QEMU machine from scratch:

➡ [`05-custom-machine-qemu.md`](05-custom-machine-qemu.md)
