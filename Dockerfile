FROM quay.io/okd/scos-content:4.19.0-okd-scos.19-stream-coreos

COPY D42D0685.pub /etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA
COPY nvidia.repo /etc/yum.repos.d/nvidia.repo

RUN sed -i 's/enabled=0/enabled=1/' /etc/yum.repos.d/centos.repo && \
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel{,-next}-release-latest-9.noarch.rpm && \
    export KERNEL_VERSION=$(dnf list available kernel.x86_64 | tail -n1 | awk '{print $2}' | awk -F'[-.]' '{print $1"."$2"."$3"-"$4}') && \
    rpm-ostree override replace https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/os/Packages/kernel-{,core-,modules-,modules-core-,modules-extra-}${KERNEL_VERSION}.el9.x86_64.rpm && \
    dnf install -y dkms g++ && \
    dnf install -y kmod-nvidia-open-dkms libnvidia-cfg libnvidia-fbc nvidia-driver nvidia-driver-cuda nvidia-driver-cuda-libs nvidia-libXNVCtrl nvidia-libXNVCtrl-devel nvidia-modprobe nvidia-persistenced nvidia-settings nvidia-xconfig && \
    export NVIDIA_DRIVER_VERSION=$(/usr/bin/rpm -q kmod-nvidia-open-dkms | awk -F'-' '{ print $5 }') && \
    ln -s /usr/src/nvidia-open-${NVIDIA_DRIVER_VERSION} /usr/src/nvidia-${NVIDIA_DRIVER_VERSION} && \
    dkms install nvidia/${NVIDIA_DRIVER_VERSION} --force --verbose --modprobe-on-install -k ${KERNEL_VERSION}.el9.x86_64 && \
    dnf autoremove && dnf clean all && \
    ostree container commit
