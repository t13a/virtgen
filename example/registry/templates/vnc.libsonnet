// VNC gets a free port of the host. Without video, libvirt adds a cirrus card.
{ domain+: { devices+: { 'graphics:vnc': { '@type': 'vnc' } } } }
