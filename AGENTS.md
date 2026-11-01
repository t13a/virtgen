# virtgen

virtgen renders a registry of VMs, written in Jsonnet, into provisioners: the libvirt XML and the cloud-init files of each VM, plus a Makefile that creates it with virsh. [README.md](README.md) describes how to use it, how VMs are operated, and the format of a registry.

Write all documentation, code comments, commit messages, and GitHub issues and pull requests in English.

## Design principles

- **Make VMs easy to create, and stop there.** virtgen does not detect conflicts between VMs, such as two VMs with one IP or MAC address, and it does not reconcile with what was made outside it: it cannot see a complex network of the hypervisor, or VMs that other tools provisioned. That is left to libvirt and the user.
- **The renderer owns the formats, and the registry owns the VMs.** `src/main.jsonnet` knows libvirt XML, cloud-init, Make, and the sections of a VM, but not what a VM needs. Add a feature as a template, as UEFI, the options of the disks, and the fixed UUID and MAC address were added.
- **Jsonnet decides, and Make carries out.** Work out at render time whatever can be, and let `src/rules.mk` only run what `vars.mk` says, as the source of a capacity, the order of the volumes, and ProxyJump from the node URI already are. Logic in Make and the shell has caused most of the bugs.
- **Depend on first-party interfaces.** virtgen reaches libvirt through its XML and virsh, and the guest through cloud-init's NoCloud datasource, and owns the small glue between them. It does not rent third-party adaptors, such as a Terraform provider, which would need maintenance whenever they change.

## How the parts fit

`src/main.jsonnet` writes a directory for each VM with `vars.mk`, the files that `src/rules.mk` reads, and a `Makefile` that includes `vars.mk` and then `../rules.mk`. It also copies `rules.mk` next to those directories, so the provisioners run without the renderer. The two files share this contract, so they change together.

## Development

Build the image:

```console
$ podman build -t virtgen src
```

CI renders `example/registry` into an empty directory, so every file is validated, and requires the result to match `example/provisioners` and `example/registry/index.libsonnet`. So after a change to `src/` or `example/registry/`, render the example and commit the result with the change:

```console
$ podman run --rm --userns=keep-id -v ./example/registry:/src/registry -v ./example/provisioners:/src/provisioners virtgen
```

A push to `main` publishes the image to `ghcr.io/t13a/virtgen` as `latest`, and a tag `v*` publishes it under its version.

## Comments

Comment only what the code cannot say: knowledge from outside the code, such as why `debian13` boots with UEFI, and behavior that reading the code does not reveal, such as why `make ssh` exports `CMD`. What users need goes into README.md.
