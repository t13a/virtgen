local i = import '../index.libsonnet';
local t = i.templates;

t.base
+ t.cloud(image=i.images.debianCloud(version='12'))
+ t.sshPassword(password='P@ssw0rd')
+ t.sshNoHostKeyChecking
+ {
  node: i.nodes.localhost,
}
