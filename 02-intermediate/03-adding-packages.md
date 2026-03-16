# Adding Packages to Your Image

🟡 **Intermediate**

`core-image-minimal` is intentionally bare. This module shows you the correct ways to add software to a Yocto image — from quick one-off additions in `local.conf` to permanent changes via image recipes.

---

## Three ways to add a package

| Method | Where | Best for |
|---|---|---|
| `IMAGE_INSTALL:append` in `local.conf` | Build directory | Quick experiments, not checked into the layer |
| `IMAGE_INSTALL:append` in a `.bbappend` | Your layer | Persistent additions to an existing image |
| Custom image recipe | Your layer | Defining a new, fully specified image |

You will use all three. The custom image recipe approach is covered in the next module — this module focuses on `IMAGE_INSTALL`.

---

## How IMAGE_INSTALL works

`IMAGE_INSTALL` is the variable that lists which packages BitBake installs into the root filesystem during `do_rootfs`. It accepts package names — the same names you would see in `rpm -qa` on the target.

```conf
# local.conf
IMAGE_INSTALL:append = " packagename1 packagename2"
```

Note the leading space inside the quotes. The `:append` operator concatenates without adding whitespace, so you must include the space yourself.

---

## Finding package names

Package names in Yocto often differ from the recipe names. A recipe can produce multiple packages (e.g., `openssl` produces `openssl`, `openssl-dev`, `openssl-doc`, `libssl3`).

### Method 1: oe-pkgdata-util

```bash
# List all packages produced by a recipe
oe-pkgdata-util list-pkgs -p openssl
# openssl
# openssl-dev
# openssl-doc
# libssl3
# libssl-dev
```

### Method 2: bitbake -e

```bash
# See all variables for a recipe, including PACKAGES
bitbake -e openssl | grep "^PACKAGES="
```

### Method 3: Search OE-Core recipes

```bash
# Find which recipe provides a given package
bitbake-layers show-recipes | grep ssh
```

---

## Common packages to add

Below are packages available in OE-Core and `meta-openembedded` that are frequently needed:

### SSH server (dropbear — lightweight)

```conf
IMAGE_INSTALL:append = " dropbear"
```

Dropbear is a compact SSH server and client. After adding it and rebuilding, you can SSH into the QEMU guest:

```bash
# From host:
ssh root@192.168.7.2
```

### SSH server (OpenSSH — full-featured)

```conf
IMAGE_INSTALL:append = " openssh openssh-sshd openssh-sftp-server"
```

Use OpenSSH if you need full `scp`, `sftp`, or SSH agent forwarding support.

### Python 3

```conf
IMAGE_INSTALL:append = " python3"
```

For a more complete Python environment:

```conf
IMAGE_INSTALL:append = " python3 python3-pip python3-modules"
```

Note: `python3-modules` installs the full standard library, which is large (~20 MB). For embedded targets, prefer installing only the specific modules you need (e.g., `python3-json`, `python3-logging`).

### curl and wget

```conf
IMAGE_INSTALL:append = " curl wget"
```

### strace (debugging)

```conf
IMAGE_INSTALL:append = " strace"
```

### htop

`htop` is in `meta-openembedded/meta-oe`. You need that layer added before you can use it:

```bash
# Clone meta-openembedded (if not already done)
git clone -b scarthgap https://github.com/openembedded/meta-openembedded.git ~/yocto/meta-openembedded

# Add the meta-oe layer
bitbake-layers add-layer ~/yocto/meta-openembedded/meta-oe
```

Then:

```conf
IMAGE_INSTALL:append = " htop"
```

---

## Package groups

Package groups (`packagegroup-*.bb`) are recipes that bundle related packages. They let you add a logical set of packages with one name:

```conf
# Add SSH server + client + key utilities as a group
IMAGE_INSTALL:append = " packagegroup-core-ssh-dropbear"
```

List available package groups:

```bash
find ~/yocto/poky -name "packagegroup-*.bb" | sort
```

You can also define your own package groups in your layer — useful for grouping the packages specific to your product.

---

## Adding development tools (for on-target debugging)

For a development image with compilers and debug tools on the target itself:

```conf
IMAGE_INSTALL:append = " gcc binutils make gdb gdbserver"
EXTRA_IMAGE_FEATURES += "debug-tweaks"
```

`debug-tweaks` is an `IMAGE_FEATURES` value that:
- Allows empty root password
- Enables post-installation scripts
- Installs debug symbol packages

Never ship a production image with `debug-tweaks` enabled.

---

## IMAGE_FEATURES vs IMAGE_INSTALL

`IMAGE_FEATURES` is a higher-level mechanism. Each feature expands to a set of `IMAGE_INSTALL` entries and may also modify other aspects of the image (e.g., enabling services, setting permissions).

```conf
# IMAGE_FEATURES examples
IMAGE_FEATURES += "ssh-server-dropbear"    # installs and enables dropbear
IMAGE_FEATURES += "package-management"     # includes the package manager in the image
IMAGE_FEATURES += "read-only-rootfs"       # mounts rootfs read-only at boot
```

Check which features are available:

```bash
bitbake -e core-image-minimal | grep "^IMAGE_FEATURES"
```

---

## Rebuilding after changes to local.conf

After modifying `IMAGE_INSTALL` or `IMAGE_FEATURES`, you only need to rebuild the image recipe — not the individual packages (they are cached in sstate):

```bash
# Force the rootfs assembly step to re-run
bitbake core-image-minimal -c rootfs

# Or rebuild the whole image (BitBake will skip unchanged packages)
bitbake core-image-minimal
# Takes 1–5 minutes with a warm sstate-cache
```

---

## Verifying what is in the image

Before booting, inspect the package manifest:

```bash
cat tmp/deploy/images/qemux86-64/core-image-minimal-qemux86-64.manifest
# Lists every installed package and version
```

Inside the running QEMU guest:

```bash
rpm -qa                  # list installed packages
which dropbear           # verify a binary is present
```

---

## Next Steps

You know how to add packages. Now go further and define a complete custom image recipe that owns its own package list:

➡ [`04-custom-image.md`](04-custom-image.md)
