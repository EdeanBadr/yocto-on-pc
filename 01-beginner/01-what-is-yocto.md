# What Is Yocto?

🟢 **Beginner**

Before running any commands, you need a mental model of what Yocto actually does. Skipping this step causes confusion later — terms like "layer", "recipe", and "distro" have specific meanings that differ from how they are used in general Linux.

---

## Yocto is a build framework, not a distribution

Most Linux distributions (Ubuntu, Fedora, Debian) ship pre-compiled packages from a central repository. You install software with `apt` or `dnf` and get binaries that the distribution maintainers compiled for you.

Yocto works differently. It is a **build system** — a set of tools, metadata, and conventions that lets you compile a complete Linux distribution from source, customised for a specific hardware target. The output is not a set of packages; it is a complete filesystem image ready to flash or boot.

This distinction matters: Yocto is not something you *run*, it is something you *use to produce a system image*.

---

## The Yocto Project umbrella

"Yocto Project" is the name of a Linux Foundation collaborative project. Under that umbrella sit several components you will interact with directly:

| Component | What it is |
|---|---|
| **BitBake** | The build engine. Reads recipe files and executes tasks (fetch, configure, compile, package, deploy). Think of it as `make` but for entire OS images. |
| **OpenEmbedded-Core (OE-Core)** | The core recipe and class library. Provides base recipes for the toolchain, libc, busybox, and thousands of other packages. |
| **Poky** | A reference distribution that bundles BitBake + OE-Core + a minimal distro configuration. This is what you cloned in `00-setup/`. |
| **Layers** | Collections of recipes, machine definitions, and configuration. You compose a build by stacking layers on top of OE-Core. |

If you see "OpenEmbedded" mentioned in documentation, it refers to the broader ecosystem that Yocto is built on. OE-Core is the shared foundation; Yocto adds tooling, testing, and release structure.

---

## What BitBake does

When you run `bitbake core-image-minimal`, BitBake:

1. **Reads metadata** — scans all recipe files (`.bb`), class files (`.bbclass`), and configuration files (`.conf`) from every layer in your build.
2. **Resolves dependencies** — builds a directed acyclic graph of tasks: fetch → unpack → patch → configure → compile → install → package → image.
3. **Fetches sources** — downloads tarballs, clones git repos, or copies local files for each recipe.
4. **Executes tasks** — runs each task in dependency order, in parallel where possible.
5. **Produces artefacts** — writes the final image files to `tmp/deploy/images/<MACHINE>/`.

BitBake caches task outputs in the **sstate-cache** ([shared state cache](../docs/glossary.md#sstate-cache)). If a task's inputs have not changed since it last ran, BitBake reuses the cached output instead of recompiling. This is why a second build of the same image is dramatically faster than the first.

---

## Recipes and layers

A **recipe** (`.bb` file) describes how to build one software component: where to fetch its source, what patches to apply, how to configure and compile it, and which files to install into the image. Recipes for the kernel, BusyBox, and OpenSSH already exist in OE-Core.

A **layer** is a directory that follows a naming convention (`meta-<name>/`) and contains recipes, machine definitions, image definitions, and configuration snippets. Layers are the primary unit of sharing in the Yocto ecosystem — if someone has already written a recipe for a library you need, you add their layer rather than writing the recipe yourself.

```
meta-mylayer/
├── conf/
│   └── layer.conf          ← tells BitBake this directory is a layer
├── recipes-example/
│   └── hello/
│       └── hello_1.0.bb    ← a recipe for the "hello" program
└── recipes-core/
    └── images/
        └── my-image.bb     ← a custom image recipe
```

You will write your first layer in [`02-intermediate/02-writing-your-first-recipe.md`](../02-intermediate/02-writing-your-first-recipe.md).

---

## Machines and distros

Two configuration variables control what you build:

**`MACHINE`** — the hardware target. In this repository every target is a QEMU virtual machine:
- `qemux86-64` — 64-bit x86, the default for most tutorials here
- `qemuarm64` — 64-bit Arm (AArch64)
- `qemuarm` — 32-bit Arm

**`DISTRO`** — the distribution policy: which init system to use, which C library, compiler flags, etc. The default in Poky is `poky`, a minimal policy suitable for embedded targets.

Both variables are set in `build/conf/local.conf`, which you will edit in the next module.

---

## What Yocto is NOT

- **Not a package manager** — you do not use Yocto to install software on a running system. You define the image contents at build time.
- **Not Buildroot** — Buildroot is a simpler alternative that is faster to learn but less flexible. Yocto scales to complex, multi-layer products; Buildroot is better for very constrained, simple targets.
- **Not specific to any architecture** — Yocto targets x86, Arm, RISC-V, MIPS, PowerPC, and others. The MACHINE variable switches targets.
- **Not fast for first builds** — compiling an entire OS from source takes time. This is normal and expected.

---

## Scarthgap — the release you are using

Yocto releases are named after places in Yorkshire. **Scarthgap** is the 5.0 LTS release, supported until April 2028. All commands and layer branch names in this repository target Scarthgap.

When you search for third-party layers on [layers.openembedded.org](https://layers.openembedded.org), filter by "scarthgap" to ensure compatibility.

---

## Next Steps

You now have enough background to understand what the build system is doing. In the next module you will configure your build directory and run your first real BitBake command.

➡ [`02-first-build.md`](02-first-build.md)
