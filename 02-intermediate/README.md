# 02 — Intermediate

🟡 **Intermediate**

This module assumes you have completed the beginner track and successfully built and booted `core-image-minimal`. You are comfortable with the basic BitBake workflow and understand what layers, recipes, and the sstate-cache are.

Here you move from consuming what Poky provides to creating your own layers, recipes, and images.

## Modules

| # | File | What you learn |
|---|---|---|
| 1 | [01-understanding-layers.md](01-understanding-layers.md) | How layers are structured, how BitBake discovers them, and how to find third-party layers |
| 2 | [02-writing-your-first-recipe.md](02-writing-your-first-recipe.md) | Write a `.bb` recipe from scratch, create your own layer, and add it to the build |
| 3 | [03-adding-packages.md](03-adding-packages.md) | Add software to your image via `IMAGE_INSTALL` and by modifying image recipes |
| 4 | [04-custom-image.md](04-custom-image.md) | Create a custom image recipe that defines exactly which packages are included |
| 5 | [05-devtool-workflow.md](05-devtool-workflow.md) | Use `devtool` to modify existing recipes and test changes without a full rebuild |

## Prerequisites

- `01-beginner/` completed
- `core-image-minimal` built and booted in QEMU at least once
- Comfortable with basic BitBake concepts (layers, recipes, sstate-cache)

## Next Steps

After finishing all five modules here, continue with:

➡ [`03-advanced/`](../03-advanced/README.md)
