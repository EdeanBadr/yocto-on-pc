# 01 — Beginner

🟢 **Beginner**

This module assumes no prior Yocto experience. You only need a working Linux host (set up in [`00-setup/`](../00-setup/README.md)) and patience — the first build takes a while.

## Modules

| # | File | What you learn |
|---|---|---|
| 1 | [01-what-is-yocto.md](01-what-is-yocto.md) | The big picture: what Yocto is, what it is not, and how it relates to OpenEmbedded and Poky |
| 2 | [02-first-build.md](02-first-build.md) | Configure `local.conf` and run your first `bitbake core-image-minimal` |
| 3 | [03-booting-with-qemu.md](03-booting-with-qemu.md) | Boot the image you just built inside QEMU with `runqemu` |
| 4 | [04-exploring-the-image.md](04-exploring-the-image.md) | Poke around the running system: processes, filesystem layout, and how it differs from a desktop Linux |

## Prerequisites

- Host machine set up per [`00-setup/README.md`](../00-setup/README.md)
- `bitbake --version` returns without error
- At least 80 GB of free disk space

## Time budget

| Activity | Approximate time |
|---|---|
| Reading all 4 modules | 30–45 minutes |
| First `bitbake core-image-minimal` | 1–4 hours (network and CPU dependent) |
| Subsequent builds (sstate-cache warm) | 5–15 minutes |

## Next Steps

After finishing all four modules here, continue with:

➡ [`02-intermediate/`](../02-intermediate/README.md)
