#!/usr/bin/env bash
# install-deps.sh — Install Yocto Scarthgap host dependencies
#
# Supports: Ubuntu 22.04/24.04, Debian 12, Fedora 40, AlmaLinux/Rocky 9
# Usage: bash install-deps.sh
#
# The script must be run as a normal user; it calls sudo for privileged ops.
# It does NOT modify your shell environment or clone any repositories.

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${BOLD}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
die()     { error "$*"; exit 1; }

require_non_root() {
    if [[ "${EUID}" -eq 0 ]]; then
        die "Do not run this script as root. Run as a normal user; sudo is called internally."
    fi
}

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        DISTRO_ID="${ID}"
        DISTRO_VERSION="${VERSION_ID:-unknown}"
        DISTRO_LIKE="${ID_LIKE:-}"
    else
        die "Cannot detect distribution: /etc/os-release not found."
    fi
}

# ---------------------------------------------------------------------------
# Package lists
# ---------------------------------------------------------------------------

# Packages required by Yocto Scarthgap on Debian/Ubuntu hosts.
# Source: https://docs.yoctoproject.org/5.0/ref-manual/system-requirements.html
DEBIAN_PACKAGES=(
    # Core build tools
    build-essential
    gcc
    g++
    make
    # Python
    python3
    python3-pip
    python3-pexpect
    python3-jinja2
    python3-git
    python3-subunit
    # VCS and fetching
    git
    wget
    curl
    # BitBake / OpenEmbedded utilities
    diffstat
    unzip
    chrpath
    socat
    cpio
    # Compression
    xz-utils
    zstd
    lz4
    # Text processing
    gawk
    patch
    patchutils
    # Documentation tools (required by some recipes)
    texinfo
    # Misc build helpers
    file
    locales
    libacl1
    # QEMU — x86-64 and ARM targets
    qemu-system-x86
    qemu-system-arm
    # Optional but strongly recommended
    tmux
    tree
)

# Fedora / RHEL-family package names
FEDORA_PACKAGES=(
    # Core build tools
    gcc
    gcc-c++
    make
    # Python
    python3
    python3-pip
    python3-pexpect
    python3-jinja2
    python3-GitPython
    python3-subunit
    # VCS and fetching
    git
    wget
    curl
    # BitBake / OpenEmbedded utilities
    diffstat
    unzip
    chrpath
    socat
    cpio
    # Compression
    xz
    zstd
    lz4
    # Text processing
    gawk
    patch
    patchutils
    # Documentation tools
    texinfo
    # Misc build helpers
    file
    glibc-locale-source
    # QEMU
    qemu-system-x86
    qemu-system-arm
    # Optional
    tmux
    tree
)

# ---------------------------------------------------------------------------
# Installation routines
# ---------------------------------------------------------------------------

install_debian() {
    info "Updating package index…"
    sudo apt-get update -qq

    info "Installing ${#DEBIAN_PACKAGES[@]} packages…"
    sudo apt-get install -y --no-install-recommends "${DEBIAN_PACKAGES[@]}"

    # Ensure a UTF-8 locale exists (BitBake requires it)
    if ! locale -a 2>/dev/null | grep -qi "en_US.utf8"; then
        info "Generating en_US.UTF-8 locale…"
        sudo locale-gen en_US.UTF-8
        sudo update-locale LANG=en_US.UTF-8
    fi
}

install_fedora() {
    info "Installing ${#FEDORA_PACKAGES[@]} packages…"
    sudo dnf install -y "${FEDORA_PACKAGES[@]}"
}

install_rhel() {
    # AlmaLinux / Rocky Linux 9 — EPEL needed for some packages
    if ! rpm -q epel-release &>/dev/null; then
        info "Enabling EPEL repository…"
        sudo dnf install -y epel-release
    fi
    install_fedora
}

# ---------------------------------------------------------------------------
# Post-install checks
# ---------------------------------------------------------------------------

check_command() {
    local cmd="$1"
    if command -v "${cmd}" &>/dev/null; then
        success "${cmd} found: $(command -v "${cmd}")"
        return 0
    else
        warn "${cmd} not found in PATH after install — check for errors above."
        return 1
    fi
}

run_checks() {
    echo ""
    info "Running post-install checks…"
    local failures=0

    local required_commands=(
        git
        python3
        gcc
        g++
        make
        gawk
        patch
        chrpath
        socat
        cpio
        xz
        file
        qemu-system-x86_64
        qemu-system-arm
    )

    for cmd in "${required_commands[@]}"; do
        check_command "${cmd}" || (( failures++ )) || true
    done

    echo ""
    if [[ "${failures}" -eq 0 ]]; then
        success "All checks passed. Your host is ready for Yocto Scarthgap builds."
    else
        warn "${failures} check(s) failed. Review the warnings above before proceeding."
    fi
}

# ---------------------------------------------------------------------------
# Disk space check
# ---------------------------------------------------------------------------

check_disk_space() {
    local target_dir="${HOME}"
    local available_kb
    available_kb=$(df --output=avail -k "${target_dir}" | tail -1)
    local available_gb=$(( available_kb / 1024 / 1024 ))

    info "Available disk space in ${target_dir}: ${available_gb} GB"

    if [[ "${available_gb}" -lt 50 ]]; then
        warn "Less than 50 GB free. A full Yocto build (with sstate-cache) needs ~80–100 GB."
        warn "You may run out of space during the build."
    elif [[ "${available_gb}" -lt 100 ]]; then
        warn "Between 50–100 GB free. This may be enough for a single image build, but plan for more."
    else
        success "Disk space looks sufficient (${available_gb} GB available)."
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
    echo ""
    echo -e "${BOLD}Yocto Scarthgap (5.0 LTS) — Host Dependency Installer${RESET}"
    echo "======================================================"
    echo ""

    require_non_root
    detect_distro
    check_disk_space

    info "Detected distribution: ${DISTRO_ID} ${DISTRO_VERSION}"

    case "${DISTRO_ID}" in
        ubuntu|debian)
            install_debian
            ;;
        fedora)
            install_fedora
            ;;
        almalinux|rocky|rhel|centos)
            install_rhel
            ;;
        *)
            # Handle distros that declare themselves as debian/ubuntu compatible
            if [[ "${DISTRO_LIKE}" == *"debian"* || "${DISTRO_LIKE}" == *"ubuntu"* ]]; then
                warn "Unrecognised distro '${DISTRO_ID}' but ID_LIKE suggests Debian-family. Attempting apt install."
                install_debian
            elif [[ "${DISTRO_LIKE}" == *"fedora"* || "${DISTRO_LIKE}" == *"rhel"* ]]; then
                warn "Unrecognised distro '${DISTRO_ID}' but ID_LIKE suggests Fedora-family. Attempting dnf install."
                install_fedora
            else
                die "Unsupported distribution '${DISTRO_ID}'. Install packages manually — see 00-setup/README.md for the full list."
            fi
            ;;
    esac

    run_checks

    echo ""
    echo -e "${BOLD}Next step:${RESET}"
    echo "  Clone Poky (Scarthgap branch) and initialise your build environment:"
    echo ""
    echo "    git clone -b scarthgap git://git.yoctoproject.org/poky.git ~/yocto/poky"
    echo "    cd ~/yocto/poky"
    echo "    source oe-init-build-env ../build"
    echo ""
    echo "  Then follow 00-setup/README.md for the remaining setup steps."
    echo ""
}

main "$@"
