// Logs in over SSH with a password that the VM already has, such as the default one of an image.
// The provisioner keeps it in the file sshpass, which sshpass types. For a cloud image,
// cloudSshPassword also has cloud-init set it.
function(password) { ssh+: { password: password } }
