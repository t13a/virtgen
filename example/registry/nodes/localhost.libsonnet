{
  uri: 'qemu:///system',
  defaultNetwork: {
    name: 'default',
    ip: '192.168.122.0',
    prefix: 24,
    gateway: '192.168.122.1',
    dns: ['192.168.122.1'],
  },
  defaultPool: { name: 'default', path: '/var/lib/libvirt/images' },
}
