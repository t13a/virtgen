// The boot order of the boot disk keeps the VM from booting another disk, such as a data disk with a
// boot loader.
local i = import '../index.libsonnet';
local t = i.templates;

function(image, imageDir='../.images')
  t.sharedImage(image, imageDir) + t.vmDisk('boot', 'vda', backing=image, bootOrder=1) + {
  local vm = self,
  local seedIso = vm.name + '-seed.iso',
  seed:: seedIso,
  volumes+: { [vm.name]+: { [seedIso]: {
    upload:: seedIso,
    name: seedIso,
    target: { format: { '@type': 'raw' } },
  } } },
  domain+: { devices+: { 'disk:seed': {
    '@type': 'file', '@device': 'cdrom',
    driver: { '@name': 'qemu', '@type': 'raw' },
    source: { '@file': vm.pools[vm.name].target.path + '/' + seedIso },
    target: { '@dev': 'sda', '@bus': 'sata' },
    readonly: {},
  } } },
  // cloud-init reads a name with a dot as an FQDN, so the hostname would end at the first dot.
  metaData: { 'instance-id': vm.name, 'local-hostname': vm.name },
  // The agent's unit has no [Install] section: udev starts it when the port of base appears, and on
  // the first boot that happens before the package is installed. So the first boot starts it here.
  userData: { packages: ['qemu-guest-agent'], runcmd: ['systemctl start qemu-guest-agent'] },
  ssh: { user: image.vars.sshUser },
}
