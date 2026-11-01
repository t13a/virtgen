// A VM with more than one data disk gives each its own name, or they merge into one.
local i = import '../index.libsonnet';
local t = i.templates;

function(dev, gib, name='data', lifecyclePolicy='Reusable')
  t.vmDisk(name, dev, gib=gib, lifecyclePolicy=lifecyclePolicy)
