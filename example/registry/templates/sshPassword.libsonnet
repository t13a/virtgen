// A password that the VM already has, such as the default one of an image. For a cloud image,
// cloudSshPassword also has cloud-init set it.
function(password) { ssh+: { password: password } }
