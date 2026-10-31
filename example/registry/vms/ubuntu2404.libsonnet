local i = import '../index.libsonnet';
local t = i.templates;

t.base
+ t.cloud(image=i.images.ubuntuCloud(version='24.04'))
+ t.cloudStaticIp(ip='192.168.122.11')
+ t.cloudSshPassword(password=i.secrets.login.password, hash=i.secrets.login.hash)
+ t.sshNoHostKeyChecking
+ t.dataDisk(dev='vdb', gib=10)
+ {
  node: i.nodes.localhost,
  domain+: { autostart:: true, memory+: { '#text': 4096 }, vcpu: 2 },
  userData+: { packages+: ['git'] },
}
