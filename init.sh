
bash -n "$0" || exit 1

set -x

[[ -n "$1" ]]

rm disk.raw
rm disk.qcow2

[[ "$1" == "-r" ]] && {
  qemu-img create -f raw disk.raw 10G
  exit
}

[[ "$1" == "-q" ]] && {
  qemu-img create -f qcow2 disk.qcow2 10G
  exit
}

