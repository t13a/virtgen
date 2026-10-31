// Trusts the host key of the VM without checking it, since the key changes every time the VM is created.
{ ssh+: { options+: { StrictHostKeyChecking: 'no', UserKnownHostsFile: '/dev/null' } } }
