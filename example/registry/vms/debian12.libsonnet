local r = import '../index.jsonnet';
local t = r.templates;

t.base
+ t.cloud(image=r.images.debianCloud(version='12'))
+ t.sshPassword(password='P@ssw0rd')
+ t.noHostKeyChecking
+ {
  node: r.nodes.localhost,
}
