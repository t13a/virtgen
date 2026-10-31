// Boots a live image from a CD-ROM. The VM has no disk, so nothing survives a shutdown.
local imageVolume = import 'imageVolume.libsonnet';

function(image, imageDir='../../.images') imageVolume(image, imageDir) + {
  local vm = self,
  domain+: { devices+: { 'disk:sda': {
    '@type': 'volume', '@device': 'cdrom',
    driver: { '@name': 'qemu', '@type': image.format },
    source: { '@pool': vm.node.imagePool.name, '@volume': image.volume },
    target: { '@dev': 'sda', '@bus': 'sata' },
    readonly: {},
    // libvirt boots from the hard disk unless a device has a boot order.
    boot: { '@order': 1 },
  } } },
}
