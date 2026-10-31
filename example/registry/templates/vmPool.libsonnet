// The VM's own pool: a directory in the default pool of the node, for the volumes of this VM alone.
{
  local vm = self,
  pools+: { [vm.name]: {
    autostart:: true,
    '@type': 'dir',
    name: vm.name,
    target: { path: vm.node.defaultPool.path + '/' + vm.name },
  } },
}
