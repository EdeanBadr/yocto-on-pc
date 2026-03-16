# yocto-on-pc — Claude Code Context

Tutorial repository teaching Yocto Project using QEMU simulation only. No real hardware. Audience ranges from beginners to advanced embedded Linux developers.

## Repo Structure

```
yocto-on-pc/
├── CLAUDE.md
├── README.md                        ← Landing page (done)
├── 00-setup/
│   ├── README.md
│   └── scripts/install-deps.sh
├── 01-beginner/
│   ├── README.md
│   ├── 01-what-is-yocto.md
│   ├── 02-first-build.md
│   ├── 03-booting-with-qemu.md
│   └── 04-exploring-the-image.md
├── 02-intermediate/
│   ├── README.md
│   ├── 01-understanding-layers.md
│   ├── 02-writing-your-first-recipe.md
│   ├── 03-adding-packages.md
│   ├── 04-custom-image.md
│   └── 05-devtool-workflow.md
├── 03-advanced/
│   ├── README.md
│   ├── 01-bsp-layers-explained.md
│   ├── 02-writing-a-bsp-layer.md
│   ├── 03-kernel-configuration.md
│   ├── 04-kernel-fragments.md
│   └── 05-custom-machine-qemu.md
├── docs/
│   ├── wsl2-setup.md
│   ├── troubleshooting.md
│   └── glossary.md
└── resources.md
```

## Content Rules

- **QEMU only** — never write steps that require physical hardware. All `MACHINE` targets must be `qemux86-64`, `qemuarm`, `qemuarm64`, or similar QEMU targets.
- **Yocto release: Scarthgap (5.0 LTS)** — all commands, layer branches, and variable names must match this release.
- Every module file starts with a difficulty badge: `🟢 Beginner`, `🟡 Intermediate`, or `🔴 Advanced`.
- Every module file ends with a `## Next Steps` section pointing to the next file.
- Code blocks must specify the language or context: ` ```bash `, ` ```bitbake `, ` ```conf `.
- Shell commands that take a long time (e.g. `bitbake`) must include a time estimate comment.
- File paths shown in tutorials are relative to the Poky clone root unless stated otherwise.

## Writing Style

- Second person ("you"), present tense, direct and concise.
- Explain *why* before *how* — never drop a command without context.
- Beginners module: define every Yocto-specific term on first use. Link to `docs/glossary.md`.
- Intermediate/Advanced modules: assume Yocto fundamentals, no hand-holding on basic Linux.
- No filler phrases like "Great!", "Simply run...", "Easy!".

## Key Yocto Facts to Get Right

- Build directory is typically `../build` relative to the Poky clone (set by `oe-init-build-env`)
- `local.conf` and `bblayers.conf` live in `build/conf/`
- `MACHINE` and `DISTRO` are set in `local.conf`
- `runqemu` is called *after* a successful `bitbake <image>`
- `sstate-cache` is why incremental builds are fast — worth explaining to beginners
- `devtool` lives in Poky's `scripts/` and is available after `source oe-init-build-env`
- Layer compatibility is checked with `bitbake-layers show-layers`

## Completed Files

- `README.md` ✅

## In Progress / To Do

- `00-setup/README.md`
- `00-setup/scripts/install-deps.sh`
- `01-beginner/` — all 4 modules
- `02-intermediate/` — all 5 modules
- `03-advanced/` — all 5 modules
- `docs/glossary.md`
- `docs/troubleshooting.md`
- `docs/wsl2-setup.md`
- `resources.md`
