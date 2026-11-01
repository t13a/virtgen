// libvirt adds a video device only along with a remote display. Any model works with vnc and spice;
// vga is QEMU's standard card, and qxl suits spice best.
function(model='vga') { domain+: { devices+: { video: { model: { '@type': model } } } } }
