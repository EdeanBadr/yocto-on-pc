# Writing Your First Recipe

🟡 **Intermediate**

A recipe (`.bb` file) is a set of instructions that tells BitBake how to fetch, build, and install one software component. In this module you create a layer from scratch, write a recipe for a small C program, and add it to your image.

---

## What you will build

A tiny C program called `hello-yocto` that prints a message and exits. Simple enough to keep the recipe short — complex enough to cover the key recipe concepts.

---

## Step 1 — Create the layer

Layers live alongside Poky, not inside it:

```bash
# From ~/yocto/ (parent of poky/)
cd ~/yocto

# Poky provides a script to create a layer skeleton
source poky/oe-init-build-env build   # re-source if needed

bitbake-layers create-layer ../meta-mylayer
```

`bitbake-layers create-layer` generates:

```
meta-mylayer/
├── conf/
│   └── layer.conf
├── recipes-example/
│   └── example/
│       └── example_0.1.bb
└── README
```

You can delete `recipes-example/` — it is just a placeholder.

### Register the layer

```bash
bitbake-layers add-layer ../meta-mylayer
```

Verify:

```bash
bitbake-layers show-layers
# meta-mylayer should appear with priority 6
```

---

## Step 2 — Write the C source

The recipe will fetch this source file. For a real project you would point `SRC_URI` at a git repo or tarball. For this tutorial, store the source inside the layer itself using a `file://` URI.

Create the source file:

```bash
mkdir -p ~/yocto/meta-mylayer/recipes-hello/hello-yocto/files
```

```bash
cat > ~/yocto/meta-mylayer/recipes-hello/hello-yocto/files/hello.c << 'EOF'
#include <stdio.h>

int main(void)
{
    printf("Hello from Yocto!\n");
    return 0;
}
EOF
```

And a minimal Makefile:

```bash
cat > ~/yocto/meta-mylayer/recipes-hello/hello-yocto/files/Makefile << 'EOF'
CC ?= gcc
CFLAGS ?= -Wall -Wextra

hello: hello.c
	$(CC) $(CFLAGS) -o hello hello.c

install:
	install -d $(DESTDIR)/usr/bin
	install -m 0755 hello $(DESTDIR)/usr/bin/hello-yocto

clean:
	rm -f hello
EOF
```

---

## Step 3 — Write the recipe

```bash
cat > ~/yocto/meta-mylayer/recipes-hello/hello-yocto/hello-yocto_1.0.bb << 'EOF'
SUMMARY = "A minimal hello-world program for Yocto tutorial purposes"
DESCRIPTION = "Prints a greeting. Used to demonstrate recipe structure in meta-mylayer."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# Local files relative to this recipe file
SRC_URI = "file://hello.c \
           file://Makefile"

# BitBake unpacks SRC_URI into ${WORKDIR}. Tell it to look there for sources.
S = "${WORKDIR}"

# do_compile: runs make in ${S}
do_compile() {
    oe_runmake
}

# do_install: copies artefacts into the staging area (${D})
do_install() {
    oe_runmake install DESTDIR=${D}
}
EOF
```

### Recipe anatomy

| Variable / function | Purpose |
|---|---|
| `SUMMARY` | One-line description, shown in package listings |
| `LICENSE` | SPDX licence identifier |
| `LIC_FILES_CHKSUM` | Checksum of the licence file — BitBake refuses to build if this changes |
| `SRC_URI` | List of sources to fetch: tarballs, git repos, or local `file://` paths |
| `S` | The directory where BitBake unpacks/finds the source (`${WORKDIR}` for local files) |
| `do_compile` | Shell function executed during the compile task |
| `do_install` | Shell function that copies files into `${D}` (the staging area) |
| `oe_runmake` | BitBake helper that calls `make` with the right cross-compile environment |

`${D}` is the **destination directory** — a staging tree that mirrors the target filesystem root. Files placed in `${D}/usr/bin/` end up at `/usr/bin/` on the target.

---

## Step 4 — Check the recipe parses

```bash
cd ~/yocto/build
bitbake hello-yocto -c fetch
# Should complete without error — fetches the local files into WORKDIR
```

```bash
bitbake hello-yocto
# Fetches, compiles, and stages hello-yocto
# Takes < 1 minute
```

If there is a parse error, BitBake prints the file and line number. Common mistakes:
- Tabs in Makefile replaced with spaces (Makefiles require literal tabs)
- `LIC_FILES_CHKSUM` MD5 mismatch — compute with `md5sum $COMMON_LICENSE_DIR/MIT`

---

## Step 5 — Add to an image and test

To see `hello-yocto` in your image, add it to `IMAGE_INSTALL` in `local.conf`:

```conf
IMAGE_INSTALL:append = " hello-yocto"
```

Then rebuild the image:

```bash
# Incremental — only rebuilds what changed
bitbake core-image-minimal
```

Boot it and verify:

```bash
runqemu qemux86-64 core-image-minimal nographic
# Inside QEMU:
hello-yocto
# Hello from Yocto!
```

---

## Fetching from a git repository

For a real project, replace the `file://` URIs with a git source:

```bitbake
SRC_URI = "git://github.com/example/myapp.git;protocol=https;branch=main"
SRCREV = "abc1234def5678..."   # exact commit SHA

S = "${WORKDIR}/git"
```

`SRCREV` pins the build to a specific commit. BitBake caches the clone in `DL_DIR` (download directory) so subsequent builds do not re-clone.

---

## Fetching a tarball

```bitbake
SRC_URI = "https://example.com/releases/myapp-${PV}.tar.gz"
SRC_URI[sha256sum] = "abc123..."   # sha256 of the tarball

S = "${WORKDIR}/myapp-${PV}"
```

`${PV}` expands to the version from the recipe filename (`1.0` in `myapp_1.0.bb`). The checksum is mandatory — BitBake refuses to use a tarball whose hash does not match.

---

## Next Steps

Your layer exists and your first recipe builds. Now add more packages to your image using `IMAGE_INSTALL`:

➡ [`03-adding-packages.md`](03-adding-packages.md)
