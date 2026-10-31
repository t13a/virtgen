// A data disk in the VM's own pool. By default it survives `make down`; `make delete-all` removes it.
// A VM with more than one data disk gives each its own name, which names the disk, its volume and
// its serial.
function(dev, gib, name='data', lifecyclePolicy='Reusable') {
  local vm = self,
  local volume = vm.name + '-' + name + '.qcow2',
  volumes+: { [vm.name]+: { [volume]: {
    lifecyclePolicy:: lifecyclePolicy,
    name: volume,
    capacity: { '@unit': 'GiB', '#text': gib },
    target: { format: { '@type': 'qcow2' } },
  } } },
  // The same driver as the disk of cloud. The serial makes the disk /dev/disk/by-id/virtio-<name> in the
  // guest, whatever device file the guest gives it.
  domain+: { devices+: { ['disk:' + name]: {
    '@type': 'volume', '@device': 'disk',
    driver: { '@name': 'qemu', '@type': 'qcow2', '@cache': 'none', '@discard': 'unmap' },
    source: { '@pool': vm.name, '@volume': volume },
    target: { '@dev': dev, '@bus': 'virtio' },
    serial: name,
  } } },
}
