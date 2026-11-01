local i = import '../index.libsonnet';
local t = i.templates;

t.base
+ t.live(image=i.images.debianLive(version='13.7.0', flavor='gnome'))
+ t.bootDisk(gib=20)
+ t.video(model='qxl')
+ t.spice
+ {
  node: i.nodes.localhost,
  domain+: { memory+: { '#text': 4096 }, vcpu: 2 },
}
