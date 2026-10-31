// Boots with UEFI firmware (OVMF) instead of the BIOS. A headless Debian 13 cloud image needs it: under
// the BIOS its GRUB loads a legacy VGA driver, which resets the VM over and over when there is no video
// device, and GRUB for UEFI has no such driver. Each VM gets a file for its UEFI variables, which
// `make delete` removes along with the domain.
// libvirt picks the firmware that matches secureBoot. With it, the firmware enforces Secure Boot with the
// keys of Microsoft, which sign the shim of most distributions. Without it, which is the default,
// unsigned kernel modules, such as those that DKMS builds, load too.
function(secureBoot=false) { domain+: { os+: {
  '@firmware': 'efi',
  firmware: {
    'feature:secure-boot': { '@name': 'secure-boot', '@enabled': if secureBoot then 'yes' else 'no' },
    [if secureBoot then 'feature:enrolled-keys']: { '@name': 'enrolled-keys', '@enabled': 'yes' },
  },
} } }
