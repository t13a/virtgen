# virtgen

virtgen renders a registry of VMs, written in Jsonnet, into provisioners: the libvirt XML and the cloud-init files of each VM, plus a Makefile that creates it with virsh. [README.md](README.md) describes its goals and concepts, and how to use it.

Write all documentation, code comments, commit messages, and GitHub issues and pull requests in English.

## Design principles

- **Make VMs easy to create, and stop there.** virtgen does not detect conflicts between VMs, such as two VMs with one IP or MAC address, and it does not reconcile with what was made outside it: it cannot see a complex network of the hypervisor, or VMs that other tools provisioned. That is left to libvirt and the user.
- **The renderer owns the formats, and the registry owns the VMs.** `src/main.jsonnet` knows libvirt XML, cloud-init, Make, and the sections of a VM, but not what a VM needs. Add a feature as a template, as UEFI, the options of the disks, and the fixed UUID and MAC address were added.
- **Jsonnet decides, and Make carries out.** Work out at render time whatever the VM decides, and let `src/rules.mk` only run what `vars.mk` says, as the source of a capacity and the order of the volumes already are. Logic in Make and the shell has caused most of the bugs. The exception is how the client reaches the node, which can change after rendering: the URI of a run, and the ProxyJump that follows from it, are worked out at run time.
- **Depend on first-party interfaces.** virtgen reaches libvirt through its XML and virsh, and the guest through cloud-init's NoCloud datasource, and owns the small glue between them. It does not rent third-party adaptors, such as a Terraform provider, which would need maintenance whenever they change.

## Layout

- `src/` holds what goes into the image:
  - `main.jsonnet` renders the VMs into provisioners, and checks them against the format in README.md.
  - `rules.mk` defines the targets of each VM's Makefile.
  - The `Makefile` runs the renderer.
- `example/registry/` is an example registry, and `example/provisioners/` what the image renders from it. Its `.images/` caches the images that the VMs download.

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

After a change to `src/`, run the end-to-end test, which creates a VM on a real node and checks what each target of its provisioner does. [tests/README.md](tests/README.md) describes what it checks, and how to run it.

Only a version tag, such as `v0.1.0`, publishes the image to `ghcr.io/t13a/virtgen`, under its version and as `latest`, once the end-to-end test passes on the runner. The test also runs when the workflow is run by hand from the Actions tab. Pull requests and pushes to `main` run only the render of the example.

## Comments

Comment only what the code cannot say: knowledge from outside the code, such as why `debian13` boots with UEFI, and behavior that reading the code does not reveal, such as why `make ssh` exports `CMD`. What users need goes into README.md.
