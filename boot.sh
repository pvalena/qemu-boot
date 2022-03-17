
bash -n "$0" || exit 1
set -xe

cd "$(dirname "$0")"

t () {
  [[ "$1" == "-t" ]] && shift && exec timeout 60 "$0" "$@"
}

t "$@" ||:

[[ "$1" == '-a' ]] && {
  echo "> aarch"

  #cp $(dirname $(which qemu-img))/../share/qemu/edk2-aarch64-code.fd .
  #cp $(dirname $(which qemu-img))/../share/qemu/edk2-arm-vars.fd .

  exec \
  /opt/homebrew/bin/qemu-system-aarch64 \
    -m 2048 -smp 1 \
    -device virtio-serial \
    -accel hvf -accel tcg -cpu cortex-a57 -M virt,highmem=off \
    -drive file=/opt/homebrew/share/qemu/edk2-aarch64-code.fd,if=pflash,format=raw,readonly=on \
    -drive if=virtio,file=disk.qcow2 \
    -cdrom RHEL-9.0.0-20210316.8-BaseOS-aarch64-boot.iso \
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
    -cdrom ./RHEL-9.0.0-20210316.8-aarch64-dvd1.iso \
    -nographic \
    -boot d

  exit


    -drive file=/Users/pvalena/.local/share/containers/podman/machine/qemu/podman-machine-default_ovmf_vars.fd,if=pflash,format=raw \
    -cpu cortex-a72 \

}

[[ "$1" == "-x" ]] && {
  echo "> x86"

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
    -drive "if=virtio,format=qcow2,file=disk.qcow2,discard=on" \
    -cdrom RHEL-9.0.0-20210316.8-BaseOS-x86_64-boot.iso \
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
    -drive file=disk.qcow2,format=qcow2 \
    -cdrom RHEL-9.0.0-20210316.8-BaseOS-x86_64-boot.iso \
    -m 2G \
    -nographic

  exit
}

[[ "$1" == "-b" ]] && {
  echo "> x86 : uefi"

  exec \
  qemu-system-x86_64 \
    -boot menu=on \
    -m 8G \
    -cpu max \
    -smp 4 \
    -drive file=disk.qcow2,format=qcow2 \
    -bios /usr/share/edk2/ovmf/OVMF_CODE.fd \
    -cdrom RHEL-9.0.0-20210316.8-BaseOS-x86_64-boot.iso \
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
  echo "> x86 : uefi"

  exec \
  qemu-system-x86_64 \
    -boot menu=on \
    -m 8G \
    -cpu max \
    -smp 4 \
    -drive file=disk.qcow2,format=qcow2 \
    -bios /usr/share/edk2/ovmf/OVMF_CODE.fd \
    -cdrom ./RHEL-9.0.0-20210316.8-x86_64-dvd1.iso \
    -accel kvm \
    -serial mon:stdio \
    -device virtio-net-pci,netdev=net \
    -netdev user,id=net,ipv6=off \
    -nographic \
    -chardev vc,id=vc1,width=$(tput cols),height=$(tput lines) -mon chardev=vc1

  exit

    -append 'console=ttyS0' \
    -cdrom RHEL-9.0.0-20210316.8-BaseOS-x86_64-boot.iso \

  net.ifnames.prefix=net inst.text console=ttyS0

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



