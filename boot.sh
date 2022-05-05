#!/usr/bin/env bash
#
# Script for booting with QEMU with various architectures
#
#   You need to modify image file
#   and create disk.qcow2 or disk.raw yourself
#
#   https://gist.github.com/500c3779a18976ceb394a87a08708758
#
#   I personally use '-u'.
#
#

bash -n "$0" || exit 1
set -xe

cd "$(dirname "$0")"

t () {
  [[ "$1" == "-t" ]] && shift && exec timeout 60 "$0" "$@"
}

abort () {
  echo "$@" >&2
  exit 1
}

iso () {
  local F="$(ls -d RHEL-*"$1"*.iso | tail -n 1)"

  [[ -r "$F" ]] || abort "File not found: $F"

  echo "$F"
}

warn () {
  echo "Warning:" "$@" >&2
}

ovmf () {
  echo "OVMF is needed to boot uefi images"

  [[ "$(whoami)" == root ]] && SUDO=sudo || SUDO=
  $SUDO dnf install '/usr/share/edk2/ovmf/OVMF_CODE.fd'
}

t "$@" ||:

[[ "$1" == '-a' ]] && {
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
    -drive if=virtio,file=disk${2:+-$2}.qcow2 \
    -cdrom $(iso aarch64-boot) \
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
    -device virtio-net-pci,netdev=net \
    -device virtio-mouse-pci \
    -netdev user,id=net,ipv6=off \
    -drive "if=pflash,format=raw,file=./edk2-aarch64-code.fd,readonly=on" \
    -drive "if=pflash,format=raw,file=./edk2-arm-vars.fd,discard=on" \
    -drive "if=virtio,format=raw,file=./disk.raw,discard=on" \
    -cdrom $(iso aarch64-dvd) \
    -nographic \
    -boot d

  exit


    -drive file=/Users/pvalena/.local/share/containers/podman/machine/qemu/podman-machine-default_ovmf_vars.fd,if=pflash,format=raw \
    -cpu cortex-a72 \

}

[[ "$1" == "-x" ]] && {
  echo "> x86"
  warn "does not work yet"

  exec \
  qemu-system-x86_64 \
    -machine q35,accel=tcg \
    -smp 1 -m 2G \
    -device intel-hda \
    -device hda-output \
    -device qemu-xhci \
    -device usb-kbd \
    -device virtio-net-pci,netdev=net \
    -device virtio-mouse-pci \
    -netdev user,id=net,ipv6=off \
    -drive "if=virtio,format=qcow2,file=disk${2:+-$2}.qcow2,discard=on" \
    -cdrom $(iso x86_64-boot) \
    -nographic \
    -boot d

  exit
}

[[ "$1" == "-f" ]] && {
  echo "> x86 : fedora"

  exec \
  qemu-system-x86_64 \
    -boot menu=on \
    -cpu max \
    -accel kvm \
    -smp 1 \
    -drive file=disk${2:+-$2}.qcow2,format=qcow2 \
    -cdrom $(iso x86_64-boot) \
    -m 2G \
    -nographic

  exit
}

[[ "$1" == "-b" ]] && {
  echo "> x86 : uefi-boot"

  ovmf

  exec \
  qemu-system-x86_64 \
    -boot menu=on \
    -m 8G \
    -cpu max \
    -smp 4 \
    -drive file=disk${2:+-$2}.qcow2,format=qcow2 \
    -bios /usr/share/edk2/ovmf/OVMF_CODE.fd \
    -cdrom $(iso x86_64-boot) \
    -accel kvm \
    -serial mon:stdio \
    -device virtio-net-pci,netdev=net \
    -netdev user,id=net,ipv6=off \
    -nographic \
    -chardev vc,id=vc1,width=$(tput cols),height=$(tput lines) -mon chardev=vc1

  exit

  # kernel: net.ifnames.prefix=net inst.text console=ttyS0

}


[[ "$1" == "-u" ]] && {
  echo "> x86 : uefi-dvd"

  ovmf

  exec \
  qemu-system-x86_64 \
    -boot menu=on \
    -m 8G \
    -cpu max \
    -smp 4 \
    -drive file=disk${2:+-$2}.qcow2,format=qcow2 \
    -bios /usr/share/edk2/ovmf/OVMF_CODE.fd \
    -cdrom $(iso x86_64-dvd1) \
    -accel kvm \
    -serial mon:stdio \
    -device virtio-net-pci,netdev=net \
    -netdev user,id=net,ipv6=off \
    -nographic \
    -chardev vc,id=vc1,width=$(tput cols),height=$(tput lines) -mon chardev=vc1

  exit

    -append 'console=ttyS0' \

  # net.ifnames.prefix=net inst.text console=ttyS0

}

[[ -n "$1" ]]

exit

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


