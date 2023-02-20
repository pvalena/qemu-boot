#!/usr/bin/env bash
#
# Script for booting with QEMU with various architectures
#
#   You need to modify image file
#   and create disk.qcow2 or disk.raw yourself
#
#   https://gist.github.com/500c3779a18976ceb394a87a08708758
#
# Usage:
#
#   ./boot.sh [option] DISK ISO
#
#   See the blocks in code for options.
#   I personally use '-u'.
#
#   Don't forget to append to kernel command line:
#      inst.text console=ttyS0
#   for install.
#
# Examples:
#
#   ./boot.sh -u fedora36 Fedora-Server-dvd
#
#   ./boot.sh -u '' 'Rawhide-20220505.n.0'
#
#   ./boot.sh -u 'rhel9-22-03-18'
#

## Init

bash -n "$0" || exit 1
set -xe

cd "$(dirname "$0")"


## Methods

abort () {
  echo "$@" >&2
  exit 1
}

iso () {
  local F="$(ls -d *"$1"*.iso | tail -n 1)"

  [[ -n "$F" ]] || abort "Image file not found: *\"${1}\"*.iso"
  [[ -r "$F" ]] || abort "Image missing or unreadable: $IMG"

  echo "$F"
}

warn () {
  echo "Warning:" "$@" >&2
}

ovmf () {
  local f='/usr/share/edk2/ovmf/OVMF_CODE.fd'
  [[ -r "$f" ]] && return 0

  echo "OVMF is needed to boot uefi images"

  [[ "$(whoami)" == root ]] && SUDO= || SUDO=sudo
  $SUDO $(which dnf) install '/usr/share/edk2/ovmf/OVMF_CODE.fd'
}

escape () {
  printf "%q" "$1"

  return 0
}

## Const

DEFAULT_NET='-device virtio-net-pci,netdev=net0 -netdev user,id=net0,ipv6=off'


## Args

# Pre-switches
[[ "$1" == "-d" ]] && {
  DEV="-device $2"
  shift 2
  :
} || DEV=

[[ "$1" == "-n" ]] && {
  NET="$2"
  shift 2

  [[ -n "$NET" && "$NET" != '-' ]] \
    && NET="${NET:+-nic $NET}" \
    || NET=
  :
} || NET="$DEFAULT_NET"

[[ "$1" == "-t" ]] && {
  shift
  exec timeout 60 "$0" "$@"
}


# Main arg
ARG="$1"
shift
[[ -z "$ARG" || "${ARG:0:1}" == "-" ]] \
  && abort "Arg missing or invalid!"

# Disk image string
[[ -n "$1" ]] && {
  DSK="$1"
  shift
}
DSK="disk${DSK:+-$DSK}.qcow2"
[[ -r "$DSK" ]] || abort "Disk missing or unreadable: $DSK"

# Shift even if empty
shift ||:

# Iso file for the cdrom
[[ "${1:0:1}" != "-" ]] && {
  [[ -n "$1" ]] && {
    IMG="$1"
    shift
  }
  IMG="$(iso ${IMG:-})"
  IMG="${IMG:+-cdrom $IMG}"
  :
} || IMG=''

## Execute

[[ "$ARG" == 'AARCH' ]] && {
  echo "> aarch"
  warn "does not work yet"

  #cp $(dirname $(which qemu-img))/../share/qemu/edk2-aarch64-code.fd .
  #cp $(dirname $(which qemu-img))/../share/qemu/edk2-arm-vars.fd .

  exec \
  /opt/homebrew/bin/qemu-system-aarch64 \
    -m 2048 -smp 1 \
    -device virtio-serial \
    -accel hvf -accel tcg -cpu cortex-a57 -M virt,highmem=off \
    -drive file=/opt/homebrew/share/qemu/edk2-aarch64-code.fd,if=pflash,format=raw,readonly=on \
    -drive if=virtio,file="$DSK" \
    ${IMG} ${NET} ${DEV} \
    -nographic \
    -boot d

  exit

  exec \
  qemu-system-aarch64 \
    -machine virt,accel=hvf,highmem=off \
    -cpu host \
    -smp 1 -m 2G \
    -device intel-hda \
    -device hda-output \
    -device qemu-xhci \
    -device usb-kbd \
    -device virtio-net-pci,netdev=net0 \
    -device virtio-mouse-pci \
    -netdev user,id=net0,ipv6=off \
    -drive "if=pflash,format=raw,file=./edk2-aarch64-code.fd,readonly=on" \
    -drive "if=pflash,format=raw,file=./edk2-arm-vars.fd,discard=on" \
    -drive "if=virtio,format=raw,file=./disk.raw,discard=on" \
    ${IMG} ${NET} ${DEV} \
    -nographic \
    -boot d

  exit


    -drive file=/Users/pvalena/.local/share/containers/podman/machine/qemu/podman-machine-default_ovmf_vars.fd,if=pflash,format=raw \
    -cpu cortex-a72 \

}

[[ "$ARG" == "EXPERIMENTAL" ]] && {
  echo "> x86 : non-uefi"
  warn "does not work yet"

  exec \
  qemu-system-x86_64 \
    -machine q35,accel=tcg \
    -smp 1 -m 2G \
    -device intel-hda \
    -device hda-output \
    -device qemu-xhci \
    -device usb-kbd \
    -device virtio-net-pci,netdev=net0 \
    -device virtio-mouse-pci \
    -netdev user,id=net0,ipv6=off \
    -drive "if=virtio,format=qcow2,file=${DSK},discard=on" \
    ${IMG} ${NET} ${DEV} \
    -nographic \
    -boot d

  exit
}

[[ "$ARG" == "DEFAULT" ]] && {
  echo "> x86 : non-uefi"

  exec \
  qemu-system-x86_64 \
    -boot menu=on \
    -cpu max \
    -accel kvm \
    -smp 1 \
    -drive "file=${DSK},format=qcow2" \
    ${IMG} ${NET} ${DEV} \
    -m 2G \
    -nographic

  exit
}

[[ "$ARG" == "UEFI" ]] && {
  echo "> x86 : uefi"

  ovmf

  exec \
  qemu-system-x86_64 \
    -boot menu=on \
    -m 8G \
    -cpu max \
    -smp 4 \
    -drive "file=${DSK},format=qcow2" \
    -bios /usr/share/edk2/ovmf/OVMF_CODE.fd \
    ${IMG} ${NET} ${DEV} \
    -accel kvm \
    -serial mon:stdio \
    -nographic \
    -chardev vc,id=vc1,width=$(tput cols),height=$(tput lines) -mon chardev=vc1

  exit

    -nic tap,br=virbr0,model=e1000,"helper=/usr/libexec/qemu-bridge-helper" \

    -device virtio-net-pci,netdev=net0 \
    -netdev user,id=net0,ipv6=off \

    -append 'console=ttyS0' \

  # kernel: net.ifnames.prefix=net inst.text console=ttyS0

}

[[ "$ARG" == "NET" ]] && {
  echo "> x86 : $ARG"

  exec \
  qemu-system-x86_64 \
    -boot n \
    -m 2G \
    -cpu max \
    -smp 1 \
    ${IMG} ${NET} ${DEV} \
    -accel kvm \
    -serial mon:stdio \
    -nographic
    -chardev vc,id=vc1,width=$(tput cols),height=$(tput lines) -mon chardev=vc1

  exit

    -nic tap,br=virbr0,mac=52:54:00:12:35:58,model=e1000,"helper=/usr/libexec/qemu-bridge-helper" \

    -device e1000,netdev=net0,mac=52:54:00:12:35:58 \
    -netdev user,id=net0,ipv6=off \

    -append 'console=ttyS0' \

  # kernel: net.ifnames.prefix=net inst.text console=ttyS0

}

abort "Unknown arg: $ARG"

# Unused

  -device virtio-gpu-gl-pci \

  -device virtio-serial \

  -device virtio-rng-pci \

  -bios ./u-boot.bin


# podman
qemu-system-aarch64 \
  -m 2048 \
  -smp 1 \
  -fw_cfg name=opt/com.coreos/config,file=/Users/pvalena/.config/containers/podman/machine/qemu/podman-machine-default.ign \
  -qmp unix://var/folders/j_/1q2pjk_13rn3p64zvndjgwyc0000gn/T/podman/qmp_podman-machine-default.sock,server=on,wait=off \
  -netdev socket,id=vlan,fd=3 -device virtio-net-pci,netdev=vlan,mac=5a:94:ef:e4:0c:ee \
  -device virtio-serial \
  -chardev socket,path=/var/folders/j_/1q2pjk_13rn3p64zvndjgwyc0000gn/T/podman/podman-machine-default_ready.sock,server=on,wait=off,id=podman-machine-default_ready \
  -device virtserialport,chardev=podman-machine-default_ready,name=org.fedoraproject.port.0 \
  -accel hvf \
  -accel tcg \
  -cpu cortex-a57 \
  -M virt,highmem=off \
  -drive file=/opt/homebrew/share/qemu/edk2-aarch64-code.fd,if=pflash,format=raw,readonly=on \
  -drive file=/Users/pvalena/.local/share/containers/podman/machine/qemu/podman-machine-default_ovmf_vars.fd,if=pflash,format=raw \
  -drive if=virtio,file=/Users/pvalena/.local/share/containers/podman/machine/qemu/podman-machine-default_fedora-coreos-35.20220131.2.0-qemu.aarch64.qcow2 \
  -display none


