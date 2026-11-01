# virtgen

A generator of VM provisioners for libvirt, and a rewrite of [vm-provisioner-libvirt](https://github.com/t13a/vm-provisioner-libvirt). It renders a registry of VMs, written in Jsonnet, into provisioners. Each provisioner holds the libvirt XML and the cloud-init files of one VM, plus a Makefile that creates the VM with virsh.

**This project is in an early stage of development. Anything may change without notice.**

## Usage

Build the image. It renders a registry and validates the result.

```console
$ podman build -t virtgen src
```

Or pull it from GitHub Packages, where every push to `main` publishes it as `latest`.

```console
$ podman pull ghcr.io/t13a/virtgen
$ podman tag ghcr.io/t13a/virtgen virtgen
```

Render the registry in `registry/` into `provisioners/`. This also updates `registry/index.libsonnet`, which lists the files of the registry. It validates the files that differ from the last render, and replaces `provisioners/` only when they are valid.

```console
$ podman run --rm --userns=keep-id -v ./registry:/src/registry -v ./provisioners:/src/provisioners virtgen
```

`config` prints the VMs as the renderer sees them. It needs only the registry.

```console
$ podman run --rm --userns=keep-id -v ./registry:/src/registry virtgen config
```

Each VM gets its own Makefile. Its targets run on the host and need virsh, xorriso, curl, and ssh, plus sshpass for a VM that logs in with a password.

```console
$ make -C provisioners/debian13 up              # create and start debian13
$ make -C provisioners/debian13 wait-for-ready  # wait for SSH and cloud-init
$ make -C provisioners/debian13 ssh CMD=uptime  # run a command over SSH; SSH_EXTRA_OPTS adds options to ssh
$ make -C provisioners/debian13 stop            # shut debian13 down; stop-force cuts its power instead
$ make -C provisioners/debian13 down            # delete debian13, but keep what is Reusable or Shared
```

## Operating VMs

A VM is disposable, and its configuration is immutable: it changes only in the registry. To change a VM, change the registry, render it, and create the VM again:

- `up` creates the pools and volumes that are missing, but defines the domain every time. So `stop` and `up` apply a change to `domain.xml`, and the disks stay.
- `down` and `up` apply any other change. `down` deletes what is Disposable, and `delete-all` deletes what is Reusable too.

Changes made outside virtgen, such as a disk added with virsh or virt-manager, are out of scope: `up` defines the domain again from `domain.xml`, and `down` deletes only what the provisioner describes. So a VM leaves with `down` or `delete-all` before its file leaves the registry, because the next render has no provisioner for it. The same goes before a change that renames a pool or a volume.

`stop` waits up to `STOP_TIMEOUT` seconds, 300 by default, for the guest to shut down. `stop-force` cuts its power, as `down` and `delete-all` do, so the guest may lose what it has not written to its disks. Run `stop` before `down` when a Reusable disk should keep all of it.

To create VMs in parallel, first run `make create-shared` for one VM at a time. It uploads what the VMs share, such as their images, so that no two VMs upload the same image at once. `make download` only downloads the images, ahead of time.

## Writing a registry

A registry is a directory of Jsonnet files. `vms/` has one file per VM, and the VM is named after its file. The other directories, such as `templates/`, `images/` and `nodes/` in the example, hold what the VMs are composed from. A file reaches the others through `index.libsonnet`.

A VM is an object whose visible sections mirror the formats of their readers:

| Section | Format |
|---|---|
| `domain`, `pools`, `volumes` | libvirt XML |
| `userData`, `metaData`, `networkConfig` | cloud-init NoCloud files |
| `ssh` | `user`, `host`, `password` and `options` for `make ssh` |

`ssh.options` are ssh_config options, given to ssh as `-o`; an array becomes a comma-separated list. On a node whose URI is `qemu+ssh`, ssh reaches the VM through the host of the URI, unless the options set `ProxyJump`.

XML is written as objects:

- `'@attr'` is an attribute, and `'#text'` the text content.
- `'elem:key'` is an element `<elem>`. `:key` only names it, so that templates can merge into it.
- An array is a list of elements without names.

Hidden fields carry what the XML cannot hold:

| Where | Hidden fields |
|---|---|
| The VM | `name`, `node` (with `uri`), `seed` (the NoCloud ISO, relative to the directory of the VM) |
| `domain` | `autostart` (false by default) |
| A pool | `autostart` (false by default), `lifecyclePolicy` |
| A volume | `lifecyclePolicy`, `upload` (a file relative to the directory of the VM), `download` (the URL of that file) |

Any other hidden field inside a section must be null, which removes an element or a key that the VM inherits. So a misspelled field is an error instead of a silent default.

`lifecyclePolicy` says what becomes of a pool or a volume when its VM goes:

- `Disposable`, the default: `make down` deletes it.
- `Reusable`: it survives `make down`, and the VM uses it again. `make delete-all` deletes it.
- `Shared`: other VMs use it at the same time, so it always stays. `make create-shared` creates it.

Templates are mixins, as in `t.base + t.cloud(...) + { ... }`. A template that binds `local vm = self` sees the final VM, fully merged, so it can use what the VM sets later, such as its `name` and `node`.

A VM that logs in with a password has it in plain text in only two places, so that a repository can encrypt just those: `registry/secrets/` in the example, and the file `sshpass` of its provisioner. cloud-init gets the hash of the password, which `registry/secrets/` holds next to the password:

```console
$ openssl passwd -6  # asks for a password and prints its hash
```

## Layout

- `src/` holds what goes into the image:
  - `main.jsonnet` renders the VMs into provisioners, and checks them against the format above.
  - `rules.mk` defines the targets of each VM's Makefile. The renderer copies it into the provisioners.
  - The `Makefile` runs the renderer.
- `example/registry/` is an example registry.
- `example/provisioners/` holds what the image renders from the example registry. Its `.images/` caches the images that the VMs download.
- `AGENTS.md` is for whoever changes virtgen: its design principles and how to develop it.
