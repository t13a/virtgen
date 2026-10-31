// A blank disk to boot from, for an OS that an installer puts there, such as the installer of a live
// image. The disk boots first, so until it has an OS, the VM boots the image.
// By default it survives `make down`, as an installed OS should; `make delete-all` removes it.
local i = import '../index.libsonnet';
local t = i.templates;

function(gib, lifecyclePolicy='Reusable')
  t.vmDisk('boot', 'vda', gib=gib, lifecyclePolicy=lifecyclePolicy, bootOrder=1)
