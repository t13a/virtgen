// A blank disk to boot from, in the VM's own pool, for an OS that an installer puts there, such as
// the installer of a live image. The disk boots first, so until it has an OS, the VM boots the image.
// By default it survives `make down`, as an installed OS should; `make delete-all` removes it.
local i = import '../index.libsonnet';
local t = i.templates;

function(gib, lifecyclePolicy='Reusable') t.vmPool + {
  local vm = self,
  local volume = vm.name + '-boot.qcow2',
  volumes+: { [vm.name]+: { [volume]: {
    lifecyclePolicy:: lifecyclePolicy,
    name: volume,
    capacity: { '@unit': 'GiB', '#text': gib },
    target: { format: { '@type': 'qcow2' } },
  } } },
  // The same driver as the disk of cloud. The serial makes the disk /dev/disk/by-id/virtio-boot in the guest.
  domain+: { devices+: { 'disk:boot': {
    '@type': 'volume', '@device': 'disk',
    driver: { '@name': 'qemu', '@type': 'qcow2', '@cache': 'none', '@discard': 'unmap' },
    source: { '@pool': vm.name, '@volume': volume },
    target: { '@dev': 'vda', '@bus': 'virtio' },
    serial: 'boot',
    boot: { '@order': 1 },
  } } },
}
