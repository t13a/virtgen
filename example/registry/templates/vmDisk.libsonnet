// A disk of the VM: a qcow2 volume in the VM's own pool, attached as a virtio disk. The name, such as
// boot or data, keys the device, is the serial, and ends the name of the volume, <vm>-<name>.qcow2.
// The volume takes gib for a blank disk, or backing, an image of sharedImage, to start as an overlay
// on it.
// cache=none bypasses the page cache of the host. discard=unmap passes TRIM of the guest, such as
// from fstrim, to the image, which frees the space on the host. The serial names the disk in
// /dev/disk/by-id of the guest, as virtio-<name>, whatever device file the guest gives it.
local i = import '../index.libsonnet';
local t = i.templates;

function(name, dev, gib=null, backing=null, lifecyclePolicy='Disposable', bootOrder=null) t.vmPool + {
  local vm = self,
  local volume = vm.name + '-' + name + '.qcow2',
  volumes+: { [vm.name]+: { [volume]: {
    lifecyclePolicy:: lifecyclePolicy,
    name: volume,
    target: { format: { '@type': 'qcow2' } },
  } + (if gib != null then { capacity: { '@unit': 'GiB', '#text': gib } } else {})
    + (if backing != null then {
      backingStore: { path: vm.node.defaultPool.path + '/' + backing.volume, format: { '@type': backing.format } },
    } else {}) } },
  domain+: { devices+: { ['disk:' + name]: {
    '@type': 'volume', '@device': 'disk',
    driver: { '@name': 'qemu', '@type': 'qcow2', '@cache': 'none', '@discard': 'unmap' },
    source: { '@pool': vm.name, '@volume': volume },
    target: { '@dev': dev, '@bus': 'virtio' },
    serial: name,
  } + (if bootOrder != null then { boot: { '@order': bootOrder } } else {}) } },
}
