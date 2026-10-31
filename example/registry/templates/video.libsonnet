// A video device. libvirt adds one only along with a remote display, and most guests run without
// one. Under the BIOS, GRUB of Debian 13 cloud images does not: it loads a legacy VGA driver, and
// without a video device the VM resets over and over before Linux starts. The template uefi avoids
// that without a video device. Any model works with vnc and spice.
// vga is QEMU's standard card; qxl suits spice best.
function(model='vga') { domain+: { devices+: { video: { model: { '@type': model } } } } }
