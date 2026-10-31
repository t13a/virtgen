// Logs in over SSH with a password: cloud-init gives it to the user of the image, and the provisioner
// types it with sshpass. The password is stored in plain text, so this suits VMs for trials.
function(password) {
  userData+: { password: password, chpasswd: { expire: false }, ssh_pwauth: true },
  ssh+: { password: password },
}
