// One template touches three formats: the libvirt NIC, cloud-init's network config, and the SSH target.
// Only the address and the MAC address are per VM; the rest comes from the default network of the node.

// The MAC address maps the 2nd to 4th octets of the IPv4 address into QEMU's range 52:54:00:XX:XX:XX.
// Two VMs collide only when their addresses differ in the 1st octet alone.
local macOf(ip) =
  local octets = std.map(std.parseInt, std.split(ip, '.'));
  assert std.length(octets) == 4 && std.all([o >= 0 && o <= 255 for o in octets]) : 'not an IPv4 address: ' + ip;
  '52:54:00:%02x:%02x:%02x' % octets[1:4];

function(ip, mac=macOf(ip)) {
  local vm = self,
  local net = vm.node.defaultNetwork,
  domain+: { devices+: { 'interface:default'+: { mac: { '@address': mac } } } },
  networkConfig: { version: 2, ethernets: { eth0: {
    match: { macaddress: mac },
    addresses: [ip + '/' + net.prefix],
    routes: [{ to: 'default', via: net.gateway }],
    nameservers: { addresses: net.dns },
  } } },
  ssh+: { host: ip },
}
