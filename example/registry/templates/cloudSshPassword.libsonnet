local i = import '../index.libsonnet';
local t = i.templates;

function(password, hash) t.sshPassword(password) + {
  local vm = self,
  userData+: {
    chpasswd: { expire: false, users: [{ name: vm.ssh.user, password: hash, type: 'hash' }] },
    ssh_pwauth: true,
  },
}
