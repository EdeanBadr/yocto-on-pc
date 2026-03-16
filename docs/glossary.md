# Glossary

Definitions for Yocto Project terms as used in this repository. All definitions apply to the **Scarthgap (5.0 LTS)** release unless noted.

---

## B

### BitBake

The build engine at the core of Yocto. Reads recipe files (`.bb`), class files (`.bbclass`), and configuration files (`.conf`), resolves dependencies, and executes tasks in parallel. Conceptually similar to `make` but designed for building entire OS images rather than individual programs.

See also: [recipe](#recipe), [task](#task)

### `.bbappend`

A file that extends or overrides an existing recipe without modifying it. Named to match the recipe it targets (e.g., `busybox_%.bbappend` targets any version of `busybox`). BitBake merges `.bbappend` content into the base recipe at parse time.

### `.bbclass`

A class file containing reusable BitBake functions and variable definitions. Recipes `inherit` classes to get common behaviour (e.g., `inherit autotools` gives a recipe standard `./configure && make && make install` tasks). Class files live in `classes/` directories within layers.

### BSP (Board Support Package)

A layer that provides everything needed to build Linux for a specific hardware target: the machine definition, kernel configuration, bootloader recipes, and any vendor-specific drivers or firmware. See [machine definition](#machine-definition) and [BSP layer](#bsp-layer).

### BSP layer

A Yocto layer whose primary purpose is providing a BSP. Named `meta-<vendor>` or `meta-<board>`. Contains `conf/machine/*.conf` files and typically a `linux-yocto` `.bbappend` with kernel fragments.

---

## C

### `conf/bblayers.conf`

The file in your build directory that lists which layers BitBake includes in the build. Managed with `bitbake-layers add-layer` / `remove-layer`. Absolute paths only.

### `conf/local.conf`

The primary user configuration file in your build directory. Sets `MACHINE`, `DISTRO`, parallel job counts, and any per-build overrides. Not tracked in layer git repositories — each developer has their own.

### `COMPATIBLE_MACHINE`

A variable in a recipe or `.bbappend` whose value is a regular expression matched against `MACHINE`. If set, BitBake only builds that recipe for matching machines. Used to prevent BSP-specific recipes from being built for unrelated targets.

---

## D

### `devtool`

A command-line tool in `poky/scripts/` that supports iterative recipe development. Key subcommands: `modify` (extract source for editing), `add` (create a new recipe), `upgrade` (bump to a newer version), `deploy-target` (push built files to a running target), `finish` (write changes back to a layer).

### `DL_DIR`

The download directory. BitBake caches all fetched source tarballs and git clones here. Shared across builds. Default: `build/downloads/`. Preserving this directory dramatically speeds up rebuilds on a new machine.

### `do_compile`

The BitBake task that compiles source code. Runs in the source directory (`${S}` or `${B}`). For autotools recipes, this runs `make`. You can override it in a recipe to run custom build commands.

### `do_fetch`

The BitBake task that downloads source files listed in `SRC_URI`. Results are cached in `DL_DIR`.

### `do_install`

The BitBake task that installs compiled artefacts into the destination directory (`${D}`). Files placed in `${D}` are later split into packages by `do_package`.

### `do_rootfs`

The BitBake task that assembles the root filesystem by installing selected packages into a staging tree, then running post-installation scripts. Part of image recipes, not individual package recipes.

### `DISTRO`

The distribution policy variable. Controls which init system, C library, compiler flags, and feature set are used. The default in Poky is `poky`. Set in `local.conf` or a distro `.conf` file.

### `DISTRO_FEATURES`

A list of system-level features enabled by the distro. Recipes check this to decide which code paths to include. Common values: `systemd`, `wayland`, `x11`, `wifi`, `bluetooth`, `ipv6`.

---

## I

### `IMAGE_FEATURES`

High-level feature flags for image recipes. Each feature expands to a set of packages and may enable/disable services. Examples: `ssh-server-dropbear`, `debug-tweaks`, `read-only-rootfs`, `package-management`.

### `IMAGE_INSTALL`

The list of packages installed into the root filesystem by an image recipe. Set directly in image recipes; appended to from `local.conf` or `.bbappend` files.

---

## K

### Kconfig

The Linux kernel's configuration system. Uses a declarative language to define boolean and string options with dependencies. Yocto manages kernel Kconfig through [config fragments](#kernel-config-fragment).

### Kernel config fragment

A small `.cfg` file containing a subset of Kconfig options (e.g., `CONFIG_VIRTIO_BLK=y`). Fragments are merged with a base defconfig to produce the final `.config`. Applied via `SRC_URI` in a `linux-yocto` `.bbappend`.

---

## L

### Layer

A directory following the `meta-<name>/` naming convention that contains recipes, classes, machine definitions, and configuration snippets. The primary unit of sharing in the Yocto ecosystem. See [`BBFILE_PRIORITY`](#bbfile_priority) for how conflicts are resolved.

### `layer.conf`

The file inside `conf/layer.conf` that registers a directory as a layer with BitBake. Defines `BBFILES`, `BBFILE_COLLECTIONS`, `BBFILE_PRIORITY`, `LAYERSERIES_COMPAT`, and optionally `LAYERDEPENDS`.

### `LAYERSERIES_COMPAT`

A variable in `layer.conf` that declares which Yocto releases the layer supports. BitBake warns if this does not include the current release codename (e.g., `scarthgap`). Always keep this updated when porting a layer.

### `linux-yocto`

The primary Linux kernel recipe in OE-Core. Fetches upstream Linux source and applies Yocto metadata (patches and config fragments) on top. Supports `standard`, `tiny`, and `preempt-rt` kernel types.

---

## M

### Machine definition

A `.conf` file in `conf/machine/` that describes a hardware target. Sets `MACHINE_FEATURES`, `KERNEL_IMAGETYPE`, `PREFERRED_PROVIDER_virtual/kernel`, `SERIAL_CONSOLES`, and (for QEMU targets) `QB_*` variables.

### `MACHINE_FEATURES`

A list of hardware capabilities present on the target board. Recipes query this list to include or exclude drivers, services, and packages. Examples: `x86`, `pci`, `usbhost`, `wifi`, `bluetooth`, `screen`.

### `meta-openembedded`

A collection of layers maintained by the OpenEmbedded community that extends OE-Core with hundreds of additional recipes. Commonly used sub-layers: `meta-oe` (general), `meta-python`, `meta-networking`, `meta-multimedia`. Always check the `scarthgap` branch for compatibility.

---

## O

### OE-Core (OpenEmbedded-Core)

The shared base layer (`meta/`) maintained jointly by the Yocto Project and OpenEmbedded community. Provides the toolchain, libc, BusyBox, the kernel, and thousands of other foundation recipes.

### `oe-init-build-env`

The script sourced to initialise a build session. Adds BitBake and Poky's `scripts/` to `PATH` and creates (or re-enters) the build directory. Must be sourced in every new terminal session before running BitBake.

---

## P

### Poky

Yocto's reference distribution. Bundles BitBake, OE-Core (`meta/`), the Poky distro layer (`meta-poky/`), and BSP support for QEMU targets (`meta-yocto-bsp/`). The starting point for most Yocto-based projects.

### `PREFERRED_PROVIDER`

A variable that resolves which recipe provides a virtual target (e.g., `PREFERRED_PROVIDER_virtual/kernel = "linux-yocto"`). Allows swapping implementations without modifying recipes that depend on the virtual target.

### `PREFERRED_VERSION`

Pins a recipe to a specific version when multiple versions are available. E.g., `PREFERRED_VERSION_linux-yocto = "6.6%"` selects any 6.6.x version.

---

## R

### Recipe

A `.bb` file that tells BitBake how to build one software component: where to fetch source (`SRC_URI`), how to compile (`do_compile`), and what to install (`do_install`). Named `<name>_<version>.bb`.

### `runqemu`

A script in `poky/scripts/` that launches QEMU with the correct flags for a Yocto-built image. Reads the `.qemuboot.conf` file produced by the build to construct the QEMU command line. Available after sourcing `oe-init-build-env`.

---

## S

### Scarthgap

The codename for Yocto Project release 5.0 LTS, released April 2024. Supported until April 2028. All content in this repository targets Scarthgap. Named after Scarthgap, a geographical feature in the Yorkshire Dales.

### `sstate-cache` {#sstate-cache}

The shared state cache. Stores the output of completed BitBake tasks as archives. When inputs to a task have not changed, BitBake restores the cached output instead of re-running the task. This is the primary reason that incremental builds are fast. Default location: `build/sstate-cache/`. Can be shared across multiple build directories (set `SSTATE_DIR` in `local.conf`).

### `SRC_URI`

A space-separated list of source locations for a recipe. Supports `https://`, `git://`, `file://`, `ftp://`, and other fetcher protocols. Local files (patches, config fragments) use `file://` relative to the recipe directory.

### `SRCREV`

The git commit SHA that BitBake fetches when `SRC_URI` points to a git repository. Pinning `SRCREV` ensures reproducible builds. Use `SRCREV = "${AUTOREV}"` only during active development — never in a release layer.

---

## T

### Task

A named function inside a recipe that BitBake executes as a unit of work. Built-in tasks: `do_fetch`, `do_unpack`, `do_patch`, `do_configure`, `do_compile`, `do_install`, `do_package`. Custom tasks can be added with `addtask`.

### `tmp/`

The build output directory inside your build directory. Contains `deploy/` (final images and packages), `work/` (per-recipe working directories), and `sysroots/` (staging areas for the toolchain and native tools). Can be deleted to force a clean rebuild; the sstate-cache is unaffected.

---

## V

### Virtual provider

An abstract recipe name prefixed with `virtual/` (e.g., `virtual/kernel`, `virtual/libc`, `virtual/bootloader`). Recipes that provide the same function each declare `PROVIDES += "virtual/kernel"`. The active provider is selected with `PREFERRED_PROVIDER_virtual/kernel`.

---

## W

### WIC (OpenEmbedded Image Creator)

A tool that creates disk images with partition tables from a Kickstart-like description file (`.wks`). Produces images that can be written directly to block storage. Used when `IMAGE_FSTYPES` includes `wic` or `wic.gz`.

### Workspace layer

A temporary layer created by `devtool modify` or `devtool add` at `build/workspace/`. Has the highest layer priority during development so its recipe overrides all others. Cleaned up by `devtool finish` or `devtool reset`.
