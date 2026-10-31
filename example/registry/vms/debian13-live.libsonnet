local r = import '../index.jsonnet';
local t = r.templates;

t.base
+ t.live(image=r.images.debianLive(version='13.7.0', flavor='gnome'))
+ t.video(model='qxl')
+ t.spice
+ {
  node: r.nodes.hv1,
  domain+: { memory+: { '#text': 4096 }, vcpu: 2 },
}
