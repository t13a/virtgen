local i = import '../index.libsonnet';
local t = i.templates;

function(gib, lifecyclePolicy='Reusable')
  t.vmDisk('boot', 'vda', gib=gib, lifecyclePolicy=lifecyclePolicy, bootOrder=1)
