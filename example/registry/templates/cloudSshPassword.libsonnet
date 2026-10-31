// Logs in over SSH with a password that cloud-init gives to the user of the image. cloud-init gets
// only the hash, such as from `openssl passwd -6`, so user-data can stay in plain text.
local i = import '../index.libsonnet';
local t = i.templates;

function(password, hash) t.sshPassword(password) + {
  local vm = self,
  userData+: {
    chpasswd: { expire: false, users: [{ name: vm.ssh.user, password: hash, type: 'hash' }] },
    ssh_pwauth: true,
  },
}
