// An image as a Shared volume in the default pool of the node, so the VMs of the node use one copy.
// The image is downloaded into imageDir, relative to the directory of the VM, provisioners/<name>/.
function(image, imageDir) {
  local vm = self,
  volumes+: { [vm.node.defaultPool.name]+: { [image.volume]: {
    lifecyclePolicy:: 'Shared',
    download:: image.url,
    upload:: imageDir + '/' + image.volume,
    name: image.volume,
    target: { format: { '@type': image.format } },
  } } },
}
