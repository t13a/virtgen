// The VM of the end-to-end test, written without templates, so that the test depends only on the
// renderer and rules.mk. It has a volume of each lifecycle policy: the image is Shared, the data disk
// Reusable, and the boot disk and the seed Disposable, in a Disposable pool of the VM.
local name = 'virtgen-e2e';
local images = '/var/lib/libvirt/images';
local dir = images + '/' + name;
local image = 'debian-cloud-13-amd64.qcow2';
local seed = name + '-seed.iso';
local qcow2 = { format: { '@type': 'qcow2' } };
local disk(volume, dev) = {
  '@type': 'file',
  '@device': 'disk',
  driver: { '@name': 'qemu', '@type': 'qcow2' },
  source: { '@file': dir + '/' + volume },
  target: { '@dev': dev, '@bus': 'virtio' },
};

{
  name:: name,
  // tests/Makefile gives make the URI of E2E_URI instead.
  node:: { uri: 'qemu:///system' },
  seed:: seed,
  domain: {
    '@type': 'kvm',
    name: name,
    // make up defines the domain every time, which virsh accepts only for a UUID that it knows.
    uuid: '019b08e9-5f73-4cfc-977b-3fc02c76da33',
    memory: { '@unit': 'MiB', '#text': 1024 },
    vcpu: 1,
    // Under the BIOS, GRUB of the image resets the VM over and over without a video device.
    os: {
      '@firmware': 'efi',
      type: { '@arch': 'x86_64', '@machine': 'q35', '#text': 'hvm' },
      firmware: { feature: { '@name': 'secure-boot', '@enabled': 'no' } },
    },
    features: { acpi: {}, apic: {} },
    cpu: { '@mode': 'host-passthrough' },
    devices: {
      'disk:boot': disk(name + '-boot.qcow2', 'vda') + { boot: { '@order': 1 } },
      'disk:data': disk(name + '-data.qcow2', 'vdb') + { serial: 'data' },
      'disk:seed': {
        '@type': 'file',
        '@device': 'cdrom',
        driver: { '@name': 'qemu', '@type': 'raw' },
        source: { '@file': dir + '/' + seed },
        target: { '@dev': 'sda', '@bus': 'sata' },
        readonly: {},
      },
      // The network config that cloud-init writes on the first boot matches this MAC address.
      interface: {
        '@type': 'network',
        mac: { '@address': '52:54:00:e2:e2:e2' },
        source: { '@network': 'default' },
        model: { '@type': 'virtio' },
      },
      serial: { '@type': 'pty' },
      console: { '@type': 'pty' },
    },
  },
  pools: { [name]: { '@type': 'dir', name: name, target: { path: dir } } },
  volumes: {
    default: { [image]: {
      lifecyclePolicy:: 'Shared',
      download:: 'https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2',
      upload:: '../.images/' + image,
      name: image,
      target: qcow2,
    } },
    [name]: {
      [name + '-boot.qcow2']: {
        name: name + '-boot.qcow2',
        target: qcow2,
        backingStore: { path: images + '/' + image } + qcow2,
      },
      [name + '-data.qcow2']: {
        lifecyclePolicy:: 'Reusable',
        name: name + '-data.qcow2',
        capacity: { '@unit': 'GiB', '#text': 1 },
        target: qcow2,
      },
      [seed]: { upload:: seed, name: seed, target: { format: { '@type': 'raw' } } },
    },
  },
  metaData: { 'instance-id': name, 'local-hostname': name },
  userData: {
    chpasswd: { expire: false, users: [{ name: 'debian', password: name, type: 'text' }] },
    ssh_pwauth: true,
  },
  ssh: {
    user: 'debian',
    password: name,
    options: { StrictHostKeyChecking: 'no', UserKnownHostsFile: '/dev/null' },
  },
}
