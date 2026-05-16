#!/usr/bin/bash
set -xeuo pipefail

# Removed (unused on this hardware/workflow, kept for documentation):
#   android-tools  - no Android devices
#   bcc, bpftop, bpftrace - eBPF tracing; adds kernel attack surface, unused
#   nicstat        - laptop has no complex network stack
#   numactl        - no NUMA topology on a laptop
#   podman-machine - only needed on macOS; native Podman on Linux doesn't need it
#   tiptop         - unused perf tool
#   usbmuxd        - no iOS devices
#   waypipe        - unused remote Wayland forwarding
dnf5 install -y \
    ccache \
    dislocker \
    flatpak-builder \
    fuse-dislocker \
    git-subtree \
    intel-undervolt \
    podman-tui \
    python3-ramalama \
    restic \
    rclone \
    sysprof \
    zsh

# ROCm removed: hardware is NVIDIA + Intel iGPU, no AMD GPU present.
# mesa-libOpenCL kept (not removed): useful for Intel iGPU OpenCL.
#   rocm-hip, rocm-opencl, rocm-clinfo, rocm-smi

# qemu (full emulator) removed: ARM/MIPS/RISC-V emulation not needed on x86-only laptop.
# qemu-kvm retained for KVM virtualisation.
dnf5 --setopt=install_weak_deps=False install -y \
    libvirt \
    qemu-kvm \
    virt-manager \
    edk2-ovmf \
    guestfs-tools

# Restore UUPD update timer and Input Remapper
sed -i 's@^NoDisplay=true@NoDisplay=false@' /usr/share/applications/input-remapper-gtk.desktop
systemctl enable input-remapper.service
systemctl enable uupd.timer
systemctl enable intel-undervolt.service

# VeraCrypt — URL resolved at CI time and injected as VERACRYPT_RPM_URL build-arg
if [[ -n "${VERACRYPT_RPM_URL:-}" ]]; then
    dnf5 install -y "${VERACRYPT_RPM_URL}"
fi


dnf5 install --enable-repo="copr:copr.fedorainfracloud.org:ublue-os:packages" -y \
    ublue-setup-services

# Adding repositories should be a LAST RESORT. Contributing to Terra or `ublue-os/packages` is much preferred
# over using random coprs. Please keep this in mind when adding external dependencies.
# If adding any dependency, make sure to always have it disabled by default and _only_ enable it on `dnf install`

# Import Microsoft's signing key explicitly so dnf5 can verify package signatures.
# If CI fails with a GPG verification error here, fall back to the Flatpak:
#   com.visualstudio.code (add to system_files/etc/ublue-os/system_flatpaks and remove this block)
rpm --import https://packages.microsoft.com/keys/microsoft.asc
dnf5 config-manager addrepo \
    --set=baseurl="https://packages.microsoft.com/yumrepos/vscode" \
    --set=gpgkey="https://packages.microsoft.com/keys/microsoft.asc" \
    --id="vscode"
dnf5 config-manager setopt vscode.enabled=0
dnf5 install --enable-repo="vscode" -y \
    code

docker_pkgs=(
    containerd.io
    docker-buildx-plugin
    docker-ce
    docker-ce-cli
    docker-compose-plugin
)
dnf5 config-manager addrepo --from-repofile="https://download.docker.com/linux/fedora/docker-ce.repo"
dnf5 config-manager setopt docker-ce-stable.enabled=0
dnf5 install -y --enable-repo="docker-ce-stable" "${docker_pkgs[@]}" || {
    # Use test packages if docker pkgs is not available for f44
    if (($(lsb_release -sr) == 44)); then
        echo "::info::Missing docker packages in f44, falling back to test repos..."
        dnf5 install -y --enablerepo="docker-ce-test" "${docker_pkgs[@]}"
    fi
}

# Load iptable_nat module for docker-in-docker.
# See:
#   - https://github.com/ublue-os/bluefin/issues/2365
#   - https://github.com/devcontainers/features/issues/1235
mkdir -p /etc/modules-load.d && cat >>/etc/modules-load.d/ip_tables.conf <<EOF
iptable_nat
EOF
