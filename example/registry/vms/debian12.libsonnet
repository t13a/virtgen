local i = import '../index.libsonnet';
local t = i.templates;

t.base
+ t.cloud(image=i.images.debianCloud(version='12'))
+ t.cloudSshPassword(password=i.secrets.login.password, hash=i.secrets.login.hash)
+ t.sshNoHostKeyChecking
+ {
  node: i.nodes.localhost,
}
