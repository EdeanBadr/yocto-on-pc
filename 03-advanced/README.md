# 03 — Advanced

🔴 **Advanced**

This module assumes you are comfortable with the intermediate track: you can write layers and recipes, customise images, and use `devtool`. Here you move into Board Support Package (BSP) development and kernel customisation — the skills needed when adapting Yocto to new hardware (or, in our case, to a custom QEMU machine definition).

## Modules

| # | File | What you learn |
|---|---|---|
| 1 | [01-bsp-layers-explained.md](01-bsp-layers-explained.md) | What a BSP layer contains, how it differs from a software layer, and how the machine definition drives the build |
| 2 | [02-writing-a-bsp-layer.md](02-writing-a-bsp-layer.md) | Create a `meta-bsp-tutorial` layer with a custom QEMU machine definition |
| 3 | [03-kernel-configuration.md](03-kernel-configuration.md) | Understand the linux-yocto recipe, kernel config fragments, and how to audit the running kernel config |
| 4 | [04-kernel-fragments.md](04-kernel-fragments.md) | Write and apply kernel configuration fragments to enable or disable specific features |
| 5 | [05-custom-machine-qemu.md](05-custom-machine-qemu.md) | Pull all threads together: build and boot a custom QEMU machine definition with a tailored kernel |

## Prerequisites

- `02-intermediate/` completed in full
- Comfortable reading and writing BitBake recipes and `.bbappend` files
- Understanding of Linux kernel Kconfig (helpful but not required)

## Next Steps

After completing the advanced track you have a full working knowledge of Yocto from first build to custom BSP. See [`resources.md`](../resources.md) for further reading and community resources.
