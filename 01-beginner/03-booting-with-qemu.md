# Booting with QEMU

🟢 **Beginner**

You have a built image. This module shows you how to boot it using `runqemu` — Poky's wrapper around QEMU that automatically picks the right emulator flags for your MACHINE target.

---

## Prerequisites

- Completed [`02-first-build.md`](02-first-build.md) — `core-image-minimal` built successfully
- `oe-init-build-env` sourced in your current shell session
- QEMU packages installed (done by `00-setup/scripts/install-deps.sh`)

---

## Why runqemu, not qemu directly?

`runqemu` is a script in `poky/scripts/` that reads the `.qemuboot.conf` file produced by your build. It selects the correct QEMU binary (`qemu-system-x86_64`, `qemu-system-aarch64`, etc.), sets up the kernel command line, configures the tap network interface, and mounts the root filesystem — all from a single command.

Calling `qemu-system-x86_64` directly would require you to reconstruct those flags by hand. Use `runqemu` unless you have a specific reason not to.

---

## Step 1 — Source the environment (if needed)

If you opened a new terminal since the build, re-source the environment:

```bash
cd ~/yocto/poky
source oe-init-build-env ../build
```

---

## Step 2 — Boot the image

```bash
runqemu qemux86-64 core-image-minimal nographic
```

Flag breakdown:

| Argument | Meaning |
|---|---|
| `qemux86-64` | The MACHINE target — tells runqemu which image directory to look in |
| `core-image-minimal` | The image name to boot |
| `nographic` | Run without a graphical window; all output goes to the terminal |

`nographic` is the recommended mode when working over SSH or in a terminal without a desktop environment. Without it, QEMU opens a separate graphical window for the virtual display.

### What you will see

QEMU prints its version, then the kernel boots:

```
[    0.000000] Booting Linux on physical CPU 0x0
[    0.000000] Linux version 6.6.x (oe-user@oe-host) ...
...
[    3.142857] systemd[1]: Detected virtualization qemu.
...
Poky (Yocto Project Reference Distro) 5.0 qemux86-64 /dev/ttyS0

qemux86-64 login:
```

The system is ready when you see the login prompt.

---

## Step 3 — Log in

The default credentials for Poky images are:

```
Username: root
Password: (none — just press Enter)
```

```bash
qemux86-64 login: root
# Press Enter at the password prompt

root@qemux86-64:~#
```

You are now inside a running embedded Linux system — compiled from source by your own build.

---

## Step 4 — Verify it is running inside QEMU

```bash
cat /proc/cpuinfo | grep "model name" | head -1
# QEMU Virtual CPU version x.x

uname -a
# Linux qemux86-64 6.6.x #1 SMP ... x86_64 GNU/Linux

df -h
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/root        30M   28M  1.3M  96% /
```

The root filesystem is small — `core-image-minimal` is designed to be minimal. In later modules you will build larger images.

---

## Networking inside QEMU

By default, `runqemu` sets up a tap network interface. The guest gets:

- IP address: `192.168.7.2`
- Default gateway: `192.168.7.1` (the host)

Test network connectivity from inside the guest:

```bash
ping -c 3 192.168.7.1
```

If you want to SSH into the guest from the host (you will need `dropbear` or `openssh` added to the image first):

```bash
# From your host machine:
ssh root@192.168.7.2
```

`core-image-minimal` does not include an SSH server by default — you will add one in the intermediate modules.

---

## Alternative boot modes

### With a graphical window

```bash
runqemu qemux86-64 core-image-minimal
# Opens a QEMU graphical window — use the window for console input
```

### Boot a different MACHINE

If you also built `qemuarm64`:

```bash
runqemu qemuarm64 core-image-minimal nographic
```

`runqemu` automatically switches to `qemu-system-aarch64`.

### Specify a kernel and rootfs explicitly

```bash
runqemu qemux86-64 \
    tmp/deploy/images/qemux86-64/bzImage \
    tmp/deploy/images/qemux86-64/core-image-minimal-qemux86-64.rootfs.ext4 \
    nographic
```

This is useful when you have multiple image versions and want to boot a specific one.

---

## Exiting QEMU

To shut down the guest cleanly:

```bash
# Inside the QEMU guest:
poweroff
```

If the guest is unresponsive, you can force-quit QEMU by pressing the key sequence:

```
Ctrl-A, then X
```

(Hold `Ctrl`, press `A`, release both, then press `X`.) This immediately terminates the QEMU process.

---

## Troubleshooting

**`runqemu` not found**

You need to re-source the environment:

```bash
source ~/yocto/poky/oe-init-build-env ~/yocto/build
```

**`could not configure /dev/net/tun`**

The tap network setup requires either root or a kernel module. Try:

```bash
runqemu qemux86-64 core-image-minimal nographic slirp
```

`slirp` mode uses user-mode networking (no tap device needed) at the cost of slightly reduced performance. It is sufficient for internet access from within the guest.

**Kernel panic on boot**

The image file may be mismatched or corrupted. Rebuild:

```bash
bitbake core-image-minimal -c cleanall && bitbake core-image-minimal
```

More troubleshooting tips are in [`docs/troubleshooting.md`](../docs/troubleshooting.md).

---

## Next Steps

You have a working QEMU-booted embedded Linux system. Now explore what is inside it:

➡ [`04-exploring-the-image.md`](04-exploring-the-image.md)
