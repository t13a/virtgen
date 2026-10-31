local i = import '../index.libsonnet';
local t = i.templates;

t.base
+ t.cloud(image=i.images.debianCloud(version='13'))
+ t.cloudSshPassword(password=i.secrets.login.password, hash=i.secrets.login.hash)
+ t.sshNoHostKeyChecking
// GRUB of this image needs a video device, even without a remote display.
+ t.video()
+ {
  node: i.nodes.localhost,
}
