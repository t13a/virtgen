local i = import '../index.libsonnet';
local t = i.templates;

t.base
+ t.cloud(image=i.images.debianCloud(version='13'))
+ t.cloudSshPassword(password=i.secrets.login.password, hash=i.secrets.login.hash)
+ t.sshNoHostKeyChecking
+ t.uefi()
+ t.dataDisk(dev='vdb', gib=1)
+ { node: i.nodes.e2e }
