// A data disk. By default it survives `make down`; `make delete-all` removes it.
// A VM with more than one data disk gives each its own name.
local i = import '../index.libsonnet';
local t = i.templates;

function(dev, gib, name='data', lifecyclePolicy='Reusable')
  t.vmDisk(name, dev, gib=gib, lifecyclePolicy=lifecyclePolicy)
