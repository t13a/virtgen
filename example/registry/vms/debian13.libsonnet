local r = import '../index.jsonnet';
local t = r.templates;

t.base
+ t.cloud(image=r.images.debianCloud(version='13'))
+ t.sshPassword(password='P@ssw0rd')
+ t.noHostKeyChecking
// GRUB of this image needs a video device, even without a remote display.
+ t.video()
+ {
  node: r.nodes.localhost,
}
