local r = import '../index.jsonnet';
local t = r.templates;

t.base
+ t.cloud(image=r.images.debianCloud(version='12'))
+ {
  node: r.nodes.localhost,
}
