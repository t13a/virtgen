// Boots a live image from a CD-ROM. Without bootDisk the VM has no disk, so nothing survives a shutdown.
local i = import '../index.libsonnet';
local t = i.templates;

function(image, imageDir='../.images') t.sharedImage(image, imageDir) + {
  local vm = self,
  domain+: { devices+: { 'disk:live': {
    '@type': 'volume', '@device': 'cdrom',
    driver: { '@name': 'qemu', '@type': image.format },
    source: { '@pool': vm.node.defaultPool.name, '@volume': image.volume },
    target: { '@dev': 'sda', '@bus': 'sata' },
    readonly: {},
    // libvirt boots from the hard disk unless a device has a boot order. Order 1 is left to bootDisk,
    // so a VM with one boots from it once an OS is installed there, and from the image until then.
    boot: { '@order': 2 },
  } } },
}
