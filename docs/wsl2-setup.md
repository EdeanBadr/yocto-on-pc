# Yocto on WSL2

Running Yocto builds inside WSL2 (Windows Subsystem for Linux 2) is supported and works well for the QEMU-based workflow in this repository. This page covers the extra steps needed beyond the standard `00-setup/` instructions.

---

## Requirements

| Requirement | Details |
|---|---|
| Windows version | Windows 10 version 2004 (build 19041) or later; Windows 11 recommended |
| WSL version | WSL2 (not WSL1 — WSL1 lacks a real Linux kernel) |
| WSL distribution | Ubuntu 22.04 LTS or 24.04 LTS |
| RAM | 16 GB physical RAM minimum (WSL2 defaults to half your physical RAM) |
| Disk | 100 GB free on the Windows drive hosting the WSL virtual disk |

---

## Step 1 — Install WSL2 with Ubuntu

Open PowerShell as Administrator:

```powershell
wsl --install -d Ubuntu-22.04
```

If WSL was previously installed, ensure you are on version 2:

```powershell
wsl --set-default-version 2
wsl --list --verbose
# Ubuntu-22.04   Running   2   ← version must be 2
```

Restart Windows if prompted.

---

## Step 2 — Configure WSL2 memory and disk

By default WSL2 caps RAM at 50% of your physical memory. For Yocto builds with heavy parallelism you want more. Create `%USERPROFILE%\.wslconfig` (in your Windows home directory) with:

```ini
[wsl2]
memory=12GB          # Adjust to your available RAM (leave 2-4 GB for Windows)
processors=8         # Match your CPU core count
swap=8GB
```

Apply the change:

```powershell
wsl --shutdown
# Then re-open your Ubuntu terminal
```

Verify inside WSL:

```bash
free -h
# Mem: should show close to the value you set
nproc
# Should show the processor count you set
```

---

## Step 3 — Move the WSL virtual disk (optional but recommended)

By default WSL2 stores its virtual disk (`.vhdx`) on your `C:\` drive. If `C:\` is small, move it to a larger drive:

```powershell
# In PowerShell (Admin)
wsl --shutdown
wsl --export Ubuntu-22.04 D:\wsl-backup\ubuntu.tar
wsl --unregister Ubuntu-22.04
wsl --import Ubuntu-22.04 D:\wsl-vms\ubuntu D:\wsl-backup\ubuntu.tar --version 2
```

---

## Step 4 — Store Yocto files inside the WSL filesystem

**Do not** put your Yocto build inside `/mnt/c/` or `/mnt/d/` (Windows-mounted drives). File I/O across the WSL boundary is slow enough to make builds 5–10× slower.

Store everything inside the WSL virtual filesystem:

```bash
mkdir -p ~/yocto
cd ~/yocto
# Clone Poky here — inside WSL, not on /mnt/
git clone -b scarthgap git://git.yoctoproject.org/poky.git poky
```

---

## Step 5 — Install host dependencies

Inside your WSL Ubuntu terminal, follow the standard setup:

```bash
bash ~/path/to/yocto-on-pc/00-setup/scripts/install-deps.sh
```

---

## Step 6 — Increase inotify limits

Yocto's build system opens many files simultaneously. The default `inotify` limits in WSL2 are too low:

```bash
# Check current limits
cat /proc/sys/fs/inotify/max_user_watches
# Default is 8192 — too low

# Increase for the current session
sudo sysctl fs.inotify.max_user_watches=524288
sudo sysctl fs.inotify.max_user_instances=512
```

To make this persistent across WSL restarts, create a sysctl config file:

```bash
echo 'fs.inotify.max_user_watches=524288' | sudo tee /etc/sysctl.d/99-yocto.conf
echo 'fs.inotify.max_user_instances=512'  | sudo tee -a /etc/sysctl.d/99-yocto.conf
```

These settings are applied automatically when WSL boots.

---

## Step 7 — QEMU networking in WSL2

WSL2 uses NAT networking. The standard `runqemu` tap networking requires a network bridge, which WSL2 does not support by default.

Use `slirp` mode instead:

```bash
runqemu qemux86-64 core-image-minimal nographic slirp
```

`slirp` sets up user-mode networking. The guest can reach the internet through WSL2's NAT, but the host cannot initiate connections to the guest by default.

### SSH from Windows host into the QEMU guest

To SSH from Windows into the QEMU guest, forward a host port to the guest's SSH port:

```bash
runqemu qemux86-64 my-image nographic slirp \
    QB_SLIRP_OPT="-hostfwd tcp::2222-:22"
```

Then from Windows PowerShell (or any SSH client):

```powershell
ssh root@localhost -p 2222
```

From within WSL you can also SSH to the QEMU guest via localhost:

```bash
ssh root@localhost -p 2222
```

---

## Step 8 — Run the build

```bash
cd ~/yocto/poky
source oe-init-build-env ../build
# Edit conf/local.conf as described in 01-beginner/02-first-build.md
bitbake core-image-minimal
# Takes 1–4 hours on first run
```

---

## Known limitations on WSL2

| Limitation | Impact | Workaround |
|---|---|---|
| No tap networking | `runqemu` default networking fails | Use `slirp` (see Step 7) |
| VirtualBox / Hyper-V conflict | Cannot run WSL2 and VirtualBox simultaneously on some configurations | Use WSL2 exclusively, or disable Hyper-V |
| QEMU KVM acceleration unavailable | QEMU runs without hardware virtualisation | Use `noaccel` option in runqemu; builds still work, guest may be slower |
| `inotify` limits | BitBake may fail to watch enough files | Apply sysctl settings in Step 6 |
| Windows Defender scanning | Can slow down builds significantly | Add the WSL virtual disk path and Yocto directories to Windows Defender exclusions |

---

## Windows Defender exclusions (performance)

Scanning every file that Yocto creates can slow builds by 30–50%. In Windows Security → Virus & threat protection → Manage settings → Exclusions, add:

- The WSL virtual disk file (e.g., `D:\wsl-vms\ubuntu\ext4.vhdx`)
- Your Yocto directory if accessible from Windows (e.g., `\\wsl$\Ubuntu-22.04\home\<user>\yocto`)

---

## Returning to the standard setup

Once WSL2 is configured, all commands in the rest of the tutorial work without modification inside the WSL Ubuntu terminal. Continue from:

➡ [`00-setup/README.md`](../00-setup/README.md) — Step 3 (initialise the build environment)
