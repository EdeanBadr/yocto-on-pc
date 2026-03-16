# Understanding Layers

🟡 **Intermediate**

Layers are the fundamental unit of composition in Yocto. Every recipe, machine definition, distro configuration, and image recipe lives inside a layer. Understanding how BitBake discovers and prioritises layers is essential before you write your own.

---

## What a layer is

A layer is a directory that:

1. Contains a `conf/layer.conf` file that registers it with BitBake.
2. Follows the naming convention `meta-<name>/`.
3. Groups related recipes under a `recipes-<category>/` directory structure.

```
meta-example/
├── conf/
│   └── layer.conf
├── recipes-core/
│   └── images/
│       └── example-image.bb
├── recipes-example/
│   └── myapp/
│       ├── myapp_1.0.bb
│       └── myapp/
│           └── fix-makefile.patch
└── README
```

The `recipes-<category>/` naming is a convention, not enforced by BitBake. Common categories from OE-Core include `recipes-core`, `recipes-connectivity`, `recipes-extended`, `recipes-graphics`, `recipes-kernel`.

---

## layer.conf

`layer.conf` is the file that makes a directory a layer. Here is a minimal example:

```conf
# conf/layer.conf

# Add this layer's recipes to BitBake's search path
BBPATH .= ":${LAYERDIR}"

# Tell BitBake to look for .bb and .bbappend files here
BBFILES += "${LAYERDIR}/recipes-*/*/*.bb \
            ${LAYERDIR}/recipes-*/*/*.bbappend"

# Which collections does this layer declare?
BBFILE_COLLECTIONS += "example"

# Glob pattern that matches files belonging to this collection
BBFILE_PATTERN_example = "^${LAYERDIR}/"

# Priority: higher number wins when two layers define the same recipe
BBFILE_PRIORITY_example = "6"

# Which versions of OE-Core (LAYERSERIES_COMPAT) does this layer support?
LAYERSERIES_COMPAT_example = "scarthgap"
```

`LAYERSERIES_COMPAT` is checked at build time. If you add a layer whose compatibility string does not include `scarthgap`, BitBake warns you. Always keep this up to date when porting a layer to a new Yocto release.

`BBFILE_PRIORITY` resolves conflicts when two layers provide the same recipe. OE-Core uses priority 5; `meta-poky` uses 6. Your custom layers should use 7 or higher to override OE-Core recipes.

---

## bblayers.conf — registering layers

BitBake only knows about layers listed in `build/conf/bblayers.conf`. To add a layer, append its absolute path to the `BBLAYERS` variable:

```conf
BBLAYERS ?= " \
  /home/you/yocto/poky/meta \
  /home/you/yocto/poky/meta-poky \
  /home/you/yocto/poky/meta-yocto-bsp \
  /home/you/yocto/meta-example \
  "
```

Use `bitbake-layers` to manage this file instead of editing it by hand:

```bash
# Add a layer
bitbake-layers add-layer ../meta-example

# Remove a layer
bitbake-layers remove-layer ../meta-example

# Show all active layers and their priorities
bitbake-layers show-layers
```

```
layer                 path                                      priority
==========================================================================
meta                  /home/you/yocto/poky/meta                5
meta-poky             /home/you/yocto/poky/meta-poky           6
meta-yocto-bsp        /home/you/yocto/poky/meta-yocto-bsp      6
meta-example          /home/you/yocto/meta-example             7
```

`bitbake-layers add-layer` validates `LAYERSERIES_COMPAT` before adding the layer, so you get early feedback if the layer is incompatible with your Yocto release.

---

## .bbappend files — extending recipes without forking

A `.bbappend` file lets you modify an existing recipe from another layer without copying it. The file name must match the recipe it extends.

To append to `meta/recipes-core/busybox/busybox_1.36.1.bb`:

```
meta-example/
└── recipes-core/
    └── busybox/
        └── busybox_%.bbappend   ← % matches any version
```

Inside `busybox_%.bbappend`:

```bitbake
# Add an extra configuration fragment to BusyBox
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://my-busybox.cfg"
```

`FILESEXTRAPATHS:prepend` adds your layer's directory to the file search path so BitBake can find `my-busybox.cfg`. The `:prepend` operator means "insert at the front" — your path is searched before the original recipe's path.

List all active `.bbappend` files:

```bash
bitbake-layers show-appends
```

---

## Layer priority and recipe resolution

When two layers define the same recipe, BitBake uses the one from the higher-priority layer. You can verify which layer "wins" for a given recipe:

```bash
bitbake-layers show-recipes busybox
```

```
=== Matching recipes: ===
busybox:
  meta               1.36.1
  meta-example       1.36.1 (skipped)
```

If `meta-example` had a higher priority it would show as the active version.

---

## Finding third-party layers

[layers.openembedded.org](https://layers.openembedded.org) is the community index of Yocto-compatible layers. When searching, filter by **scarthgap** to find layers compatible with your release.

Common layers you will encounter:

| Layer | Purpose |
|---|---|
| `meta-openembedded` | Extended recipe set (networking, multimedia, Python, Perl, etc.) |
| `meta-raspberrypi` | BSP for Raspberry Pi (for reference — not used here, we use QEMU) |
| `meta-qt6` | Qt 6 framework |
| `meta-security` | Security hardening recipes |
| `meta-virtualization` | Docker, containerd, and container runtime support |

To add a third-party layer, clone it alongside Poky (not inside it), checkout the `scarthgap` branch, and add it with `bitbake-layers add-layer`.

---

## Inspecting the active recipe set

```bash
# List all recipes BitBake can see across all layers
bitbake-layers show-recipes

# Check where a specific variable is set and by which file
bitbake -e core-image-minimal | grep "^MACHINE="

# Show all tasks for a recipe
bitbake -c listtasks core-image-minimal
```

---

## Next Steps

You understand how layers are structured and how BitBake finds recipes. Now write your own layer and recipe:

➡ [`02-writing-your-first-recipe.md`](02-writing-your-first-recipe.md)
