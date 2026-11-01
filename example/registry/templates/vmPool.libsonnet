{
  local vm = self,
  pools+: { [vm.name]: {
    autostart:: true,
    '@type': 'dir',
    name: vm.name,
    target: { path: vm.node.defaultPool.path + '/' + vm.name },
  } },
}
