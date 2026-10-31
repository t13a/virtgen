# vm-provisioner-libvirt-ng

A rewrite of [vm-provisioner-libvirt](https://github.com/t13a/vm-provisioner-libvirt). It renders a registry of VMs, written in Jsonnet, into provisioners. Each provisioner holds the libvirt XML and the cloud-init files of one VM, plus a Makefile that creates the VM with virsh.

**This project is in an early stage of development. Anything may change without notice.**

## Usage

Build the image. It renders a registry and validates the result.

```console
$ podman build -t vm-provisioner-libvirt-ng src
```

Render the registry in `registry/` into `provisioners/`. This also updates `registry/index.libsonnet`, which lists the files of the registry. It validates the files that differ from the last render, and replaces `provisioners/` only when they are valid.

```console
$ podman run --rm --userns=keep-id -v ./registry:/src/registry -v ./provisioners:/src/provisioners vm-provisioner-libvirt-ng
```

`config` prints the VMs as the renderer sees them. It needs only the registry.

```console
$ podman run --rm --userns=keep-id -v ./registry:/src/registry vm-provisioner-libvirt-ng config
```

Each VM gets its own Makefile. Its targets run on the host and need virsh, xorriso, curl, and ssh, plus sshpass for a VM that logs in with a password.

```console
$ make -C provisioners/debian13 up              # create and start debian13
$ make -C provisioners/debian13 wait-for-ready  # wait for SSH and cloud-init
$ make -C provisioners/debian13 ssh CMD=uptime  # run a command over SSH; SSH_EXTRA_OPTS adds options to ssh
$ make -C provisioners/debian13 stop            # shut debian13 down; stop-force cuts its power instead
$ make -C provisioners/debian13 down            # delete debian13, but keep what is Reusable or Shared
```

`up` creates the pools and volumes that are missing, but defines the domain every time. So a change to `domain.xml` takes effect after `stop` and `up`, and the disks stay. Other changes take effect after `down` and `up`.

To create VMs in parallel, first run `make create-shared` for one VM at a time. It uploads what the VMs share, such as their images, so that no two VMs upload the same image at once.

A VM that logs in with a password has it in plain text in only two places, so that a repository can encrypt just those: `registry/secrets/` in the example, and the file `sshpass` of its provisioner. cloud-init gets the hash of the password, which `registry/secrets/` holds next to the password:

```console
$ openssl passwd -6  # asks for a password and prints its hash
```

## Layout

- `src/` holds what goes into the image:
  - `main.jsonnet` renders the VMs into provisioners. The comment at its top describes the VM format.
  - `rules.mk` defines the targets of each VM's Makefile. The renderer copies it into the provisioners.
  - The `Makefile` runs the renderer.
- `example/registry/` is an example registry. `vms/` has one file per VM, and each VM is composed from the other directories.
- `example/provisioners/` holds what the image renders from the example registry.
