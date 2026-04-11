# Bazzite DX (KDE + Nvidia Open + gaming + dev)
# Hardware: i9-13900HX, RTX 4070 Mobile, Intel UHD iGPU, 2560x1600 165Hz
FROM ghcr.io/ublue-os/bazzite-dx-nvidia:stable

RUN dnf remove -y \
    sunshine               \
    && true

RUN dnf install -y \
    zsh                    \
    wireguard-tools        \
    && dnf clean all

# Nvidia suspend/resume: preserve VRAM across sleep cycles
# inotify: raise limit for VS Code / JetBrains file watching
RUN echo 'fs.inotify.max_user_watches = 524288' > /usr/lib/sysctl.d/99-custom.conf

# Apply these kernel args on first boot (can't set in Containerfile):
#   rpm-ostree kargs --append=nvidia.NVreg_PreserveVideoMemoryAllocations=1
#   rpm-ostree kargs --append=nvidia.NVreg_TemporaryFilePath=/var/tmp
#
# Fan control: run `ujust install-coolercontrol` after first boot
#   (LenovoLegionLinux needs DKMS which doesn't work on atomic systems,
#    CoolerControl is the supported alternative on Bazzite)

RUN bootc container lint