local r = import '../index.jsonnet';
local t = r.templates;

t.base
+ t.cloud(image=r.images.ubuntuCloud(version='26.04'))
+ t.sshPassword(password='P@ssw0rd')
+ t.noHostKeyChecking
+ t.dataDisk(dev='vdb', gib=10)
+ t.staticIp(ip='192.168.122.12', dns=['192.168.122.1', '1.1.1.1'])
+ {
  node: r.nodes.localhost,
  domain+: { autostart:: true, memory+: { '#text': 4096 }, vcpu: 2 },
  userData+: { packages+: ['git'] },
}
