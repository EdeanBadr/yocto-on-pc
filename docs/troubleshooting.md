# Troubleshooting

Common errors encountered when following this tutorial, with explanations and fixes.

---

## Build errors

### `ERROR: Nothing PROVIDES 'virtual/kernel'`

**Cause:** The active MACHINE has no kernel provider, or the required BSP layer is not in `bblayers.conf`.

**Fix:**
```bash
bitbake-layers show-layers
# Ensure meta-yocto-bsp (or your BSP layer) is listed

# If missing, add it:
bitbake-layers add-layer ~/yocto/poky/meta-yocto-bsp
```

Also verify that `MACHINE` in `local.conf` matches a `.conf` file that exists:
```bash
find ~/yocto -name "${MACHINE}.conf" -path "*/machine/*"
```

---

### `ERROR: QA Issue: ... installed in wrong location`

**Cause:** A recipe's `do_install` placed files in `/usr/local/` or another non-standard path that Yocto considers incorrect for cross-compiled images.

**Fix:** In the recipe, use `${D}${bindir}` (`/usr/bin`) rather than `${D}/usr/local/bin`:

```bitbake
do_install() {
    install -d ${D}${bindir}
    install -m 0755 myapp ${D}${bindir}/myapp
}
```

Run `bitbake -e <recipe> | grep "^bindir="` to see the resolved path.

---

### `ERROR: Fetcher failure for URL: ...`

**Cause:** BitBake could not download a source. Usually a network issue, a changed URL, or a checksum mismatch.

**Fix — network issue:**
```bash
# Check if the URL is reachable from your host
wget -q --spider https://example.com/source.tar.gz && echo OK
```

If you are behind a proxy, set in `local.conf`:
```conf
http_proxy = "http://proxy.example.com:3128"
https_proxy = "http://proxy.example.com:3128"
```

**Fix — checksum mismatch (tarball was updated upstream):**
```bash
# Delete the cached download and let BitBake re-fetch
rm ~/yocto/build/downloads/source.tar.gz*
bitbake <recipe> -c fetch
```

Update the `SRC_URI[sha256sum]` in the recipe to match the new tarball.

---

### `ERROR: LIC_FILES_CHKSUM mismatch`

**Cause:** The licence file inside the source tarball changed between versions. BitBake refuses to continue until you acknowledge the change.

**Fix:** Inspect the new licence, confirm it is acceptable, then update the checksum in the recipe:

```bash
md5sum ~/yocto/build/downloads/unpacked/source-1.2/LICENSE
# Update LIC_FILES_CHKSUM in the recipe with the new md5
```

---

### `WARNING: ... is not compatible with your configuration`

**Cause:** A layer's `LAYERSERIES_COMPAT` does not include `scarthgap`.

**Fix:** Either use a different branch of the layer:
```bash
cd ~/yocto/meta-somelayer
git checkout scarthgap
```

Or add `scarthgap` to the layer's `LAYERSERIES_COMPAT` (if you own the layer):
```conf
LAYERSERIES_COMPAT_somelayer = "kirkstone langdale mickledore nanbield scarthgap"
```

---

### `ERROR: No space left on device`

**Cause:** The build directory ran out of disk space. Yocto builds are large — 80–100 GB for a full build.

**Fix:**
```bash
# Check what is using space
du -sh ~/yocto/build/tmp/
du -sh ~/yocto/build/sstate-cache/
du -sh ~/yocto/build/downloads/

# Delete old tmp/ (rebuilds from sstate-cache, fast)
rm -rf ~/yocto/build/tmp/

# Clean old sstate entries (keeps only the most recent)
bitbake -c cleansstate <recipe>

# Or prune sstate entries older than 30 days
find ~/yocto/build/sstate-cache -mtime +30 -delete
```

---

### `ERROR: Execution of event handler 'check_sanity_everybuild' failed`

**Cause:** Missing host packages or incorrect locale.

**Fix:** Re-run the dependency installer:
```bash
bash ~/yocto/poky/../yocto-on-pc/00-setup/scripts/install-deps.sh
```

Then verify the locale:
```bash
locale
# LANG should be en_US.UTF-8 or similar UTF-8 locale
```

If not set:
```bash
sudo locale-gen en_US.UTF-8
export LANG=en_US.UTF-8
source ~/yocto/poky/oe-init-build-env ~/yocto/build
```

---

## QEMU / runqemu errors

### `runqemu: command not found`

**Cause:** `oe-init-build-env` has not been sourced in this terminal session.

**Fix:**
```bash
source ~/yocto/poky/oe-init-build-env ~/yocto/build
```

---

### `could not configure /dev/net/tun: Operation not permitted`

**Cause:** Setting up a tap network interface requires elevated privileges or kernel module support.

**Fix — use slirp (user-mode networking):**
```bash
runqemu qemux86-64 core-image-minimal nographic slirp
```

Slirp does not require root or a tap device. The guest can reach the internet but is not directly reachable from the host via IP.

**Fix — configure tap with setuid:**
```bash
sudo chmod u+s /usr/lib/qemu/qemu-bridge-helper
# Then retry without slirp
```

---

### `Kernel panic — not syncing: VFS: Unable to mount root fs`

**Cause:** QEMU cannot find the root filesystem. This usually means the kernel was built without the virtio-blk driver, or the root device path in the kernel command line is wrong.

**Fix:**
```bash
# Verify virtio is built in
grep CONFIG_VIRTIO_BLK ~/yocto/build/tmp/work/*/linux-yocto/*/.config
# Should be: CONFIG_VIRTIO_BLK=y (not =m and not unset)

# If it is a module (=m), add a kernel fragment to force built-in:
# echo "CONFIG_VIRTIO_BLK=y" > meta-bsp-tutorial/recipes-kernel/linux/linux-yocto/virtio.cfg
```

---

### QEMU boots but hangs at login prompt with no keyboard input

**Cause:** Running without `nographic` and the graphical window has not received focus, or the terminal is in a bad state.

**Fix:** Click inside the QEMU graphical window to capture input, or use the `nographic` flag:
```bash
runqemu qemux86-64 core-image-minimal nographic
```

To release the mouse when using the graphical window: `Ctrl-Alt-G`.

---

### `ssh: connect to host 192.168.7.2 port 22: No route to host`

**Cause:** The QEMU tap network is not set up, or the guest SSH server is not running.

**Fix — check tap interface on host:**
```bash
ip addr show tap0
# Should exist and have 192.168.7.1 assigned
```

If `tap0` does not exist, the tap setup failed. Use `slirp` with port forwarding instead:
```bash
runqemu qemux86-64 my-image nographic slirp \
    QB_SLIRP_OPT="-hostfwd tcp::2222-:22"
# Then: ssh root@localhost -p 2222
```

**Fix — check SSH server is in the image:**
```bash
cat ~/yocto/build/tmp/deploy/images/qemux86-64/my-image-qemux86-64.manifest | grep dropbear
# dropbear  or openssh should appear
```

If not, add `ssh-server-dropbear` to `IMAGE_FEATURES` and rebuild.

---

## devtool errors

### `devtool modify: recipe is not currently modified`

**Cause:** You ran `devtool build` or `bitbake` on a recipe that is not in the workspace.

**Fix:** First extract it:
```bash
devtool modify <recipe>
```

---

### `devtool finish: workspace recipe not found`

**Cause:** The recipe name you passed to `devtool finish` does not match any entry in the workspace.

**Fix:**
```bash
devtool status
# Lists all recipes currently in the workspace
```

Use the exact name shown there.

---

## Slow builds

### First build takes 3+ hours

This is normal. The first build compiles the complete cross-toolchain (binutils, GCC, glibc) and then cross-compiles every package from source. Subsequent builds reuse the sstate-cache.

To speed up future builds:
- Set `BB_NUMBER_THREADS` and `PARALLEL_MAKE` to your CPU core count in `local.conf`
- Store `sstate-cache` and `downloads/` on a fast SSD
- Share a sstate-cache mirror across multiple machines (set `SSTATE_MIRRORS`)

### Rebuild after `local.conf` change is slow

If you changed `MACHINE` or `DISTRO`, most artefacts need to be recompiled because they are machine/distro-specific. This is expected. The sstate-cache from a different machine target is not reusable.

If you only changed `IMAGE_INSTALL`, only the rootfs assembly tasks re-run (fast — a few minutes).

---

## Getting more help

- [Yocto Project documentation](https://docs.yoctoproject.org/5.0/) — official Scarthgap docs
- [Yocto Project mailing list](https://lists.yoctoproject.org/g/yocto) — `yocto@lists.yoctoproject.org`
- IRC: `#yocto` on [Libera.Chat](https://libera.chat)
- [layers.openembedded.org](https://layers.openembedded.org) — layer compatibility checker
