# Bazzite DX (KDE + Nvidia Open + gaming + dev)
# Hardware: i9-13900HX, RTX 4070 Mobile, Intel UHD iGPU, 2560x1600 165Hz
FROM ghcr.io/ublue-os/bazzite-dx-nvidia:stable

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

# Encryption tools
# - dislocker/fuse-dislocker: mount BitLocker-encrypted Windows partitions
# - VeraCrypt: URL resolved at build time by the CI workflow and passed in as a build arg
ARG VERACRYPT_RPM_URL
RUN dnf5 install -y dislocker fuse-dislocker && \
    dnf5 install -y "${VERACRYPT_RPM_URL}" && \
    dnf5 clean all

RUN bootc container lint