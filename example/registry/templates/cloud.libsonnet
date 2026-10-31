// Boots a cloud image with a NoCloud seed.
local i = import '../index.libsonnet';
local t = i.templates;

function(image, imageDir='../../.images') t.sharedImage(image, imageDir) + t.vmPool + {
  local vm = self,
  local seedIso = vm.name + '-seed.iso',
  local bootVolume = vm.name + '-boot.qcow2',
  seed:: seedIso,
  volumes+: {
    [vm.name]: {
      [bootVolume]: {
        name: bootVolume,
        target: { format: { '@type': 'qcow2' } },
        backingStore: { path: vm.node.defaultPool.path + '/' + image.volume, format: { '@type': image.format } },
      },
      [seedIso]: {
        upload:: seedIso,
        name: seedIso,
        target: { format: { '@type': 'raw' } },
      },
    },
  },
  domain+: { devices+: {
    // cache=none bypasses the page cache of the host. discard=unmap passes TRIM of the guest, such as
    // from fstrim, to the image, which frees the space on the host. The serial names the disk in
    // /dev/disk/by-id of the guest, here virtio-boot. The boot order keeps the VM from booting
    // another disk, such as a data disk with a boot loader.
    'disk:boot': {
      '@type': 'volume', '@device': 'disk',
      driver: { '@name': 'qemu', '@type': 'qcow2', '@cache': 'none', '@discard': 'unmap' },
      source: { '@pool': vm.name, '@volume': bootVolume },
      target: { '@dev': 'vda', '@bus': 'virtio' },
      serial: 'boot',
      boot: { '@order': 1 },
    },
    'disk:seed': {
      '@type': 'volume', '@device': 'cdrom',
      driver: { '@name': 'qemu', '@type': 'raw' },
      source: { '@pool': vm.name, '@volume': seedIso },
      target: { '@dev': 'sda', '@bus': 'sata' },
      readonly: {},
    },
  } },
  // cloud-init reads a name with a dot as an FQDN, so the hostname would end at the first dot.
  metaData: { 'instance-id': vm.name, 'local-hostname': vm.name },
  // The agent's unit has no [Install] section: udev starts it when the port of base appears, and on
  // the first boot that happens before the package is installed. So the first boot starts it here.
  userData: { packages: ['qemu-guest-agent'], runcmd: ['systemctl start qemu-guest-agent'] },
  ssh: { user: image.vars.sshUser },
}
