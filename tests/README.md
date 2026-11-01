# End-to-end test

`make -C tests` creates a VM on a real node, runs the targets of its provisioner, and checks what each one leaves on the node.

It tests the renderer and `src/rules.mk`, not the example. Its registry, `registry/`, has one VM, `virtgen-e2e`, written in the format of a VM without templates. So a change to the templates of the example cannot break the test, or hide a bug of the rules.

## Running it

The test needs:

- **The generator:** its image, built as `virtgen` with `podman build -t virtgen src`.
- **The commands of the provisioners:** GNU Make, Bash, `virsh`, `xorriso`, `curl`, `ssh`, and `sshpass`.
- **A node:** one with OVMF, the network `default`, and the pool `default` at `/var/lib/libvirt/images`, both active. The local libvirt or [libvirt-container](https://github.com/t13a/libvirt-container) will do.

```console
$ make -C tests                                                                       # the local libvirt
$ make -C tests E2E_URI='qemu+ssh://libvirt-user@127.0.0.1:2222/system?no_verify=1'   # libvirt-container
```

| Variable | Default | Meaning |
|---|---|---|
| `E2E_URI` | `qemu:///system` | The node. The registry renders for `qemu:///system`, and the test gives this URI to `make`, as a user can. |
| `E2E_IMAGE` | `virtgen` | The image of the generator. |
| `E2E_RUN` | `podman run --rm --userns=keep-id` | How to run the image, so that it writes files as the current user. With Docker, `docker run --rm --user UID:GID`. |
| `E2E_TIMEOUT` | `900` | Seconds that each `wait-for-ready` may take. |

`make -C tests` runs the steps below in order, then `clean`. Each step is also a target that expects what the steps before it left:

- **Running a few steps:** `make -C tests render up` runs the first two and leaves the VM running for a look.
- **When a step fails:** the run stops there, and the VM stays too.
- **Cleaning up:** `make -C tests clean` runs `delete-all` of the provisioner and deletes `work/`. That directory holds the rendered provisioner, and the image when the node lacks it and the test downloads it.

## The VM

`registry/vms/virtgen-e2e.libsonnet` has each thing that the rules handle:

- **A volume of each lifecycle policy:**
  - The Debian 13 cloud image is Shared, in the pool `default`.
  - The data disk is Reusable.
  - The boot disk and the seed are Disposable.

  The data disk, the boot disk and the seed are in a Disposable pool of the VM, at `/var/lib/libvirt/images/virtgen-e2e`.
- **A capacity from each source:**
  - The image and the seed take the size of the uploaded file.
  - The boot disk takes that of its backing store, the image.
  - The data disk states 1 GiB in its XML.
- **A fixed UUID and MAC address:** they let `up` define the domain again and keep the network of the guest.
- **UEFI:** under the BIOS, GRUB of the image resets the VM over and over without a video device.
- **A login with a password:** `ssh` goes through `sshpass`.

## The steps

Each check prints `ok:` or `FAIL:`, with what it expected and what it got. The checks read the node through three helpers:

- **`state`:** the state of the domain from `virsh domstate`, or `missing`.
- **`left`:** the volumes in the directory of the VM's pool, or `-` when the directory is gone. Once `down` has undefined the pool, the directory can still hold the data disk, so `left` lists it through a transient pool on the directory.
- **`image`:** whether the image is still in the pool `default`.

The data disk is checked with a token, 32 random hex digits:

- **Writing it:** `up` writes the token to the start of the disk, raw, through `/dev/disk/by-id/virtio-data`, the name that the serial of the disk gives it. Writing raw needs no file system.
- **Making it last:** `conv=fsync` puts the token on the disk before a later step cuts the power.
- **Reading it back:** later steps read the token back. The same token means that the guest sees the same disk, with what it wrote, and not a new blank one.
- **A new token each run:** that keeps a disk that an earlier run left from passing by chance.

The steps:

1. **`render`** renders `registry/` into `work/provisioners/`, which validates the files as any render does.
   - It refuses to start when a domain or a pool named `virtgen-e2e` exists, so the test never touches what it did not create.
2. **`up`** runs `up` and `wait-for-ready`. `wait-for-ready` fails unless cloud-init finished without an error, so it also shows that the seed works. The step then checks:
   - that the VM runs;
   - that `left` lists the boot disk, the data disk and the seed;
   - that `ssh` runs a `CMD` of two lines, `echo "$HOME"` and `echo two`, and prints `/home/debian two`. So the guest expands `$HOME`, not `make` or the local shell.

   Last, it writes the token.
3. **`stop-and-up`** runs `stop`, then `up` again, which defines the domain again.
   - `stop` leaves the domain shut off.
   - The token is still on the data disk.
4. **`stop-force`** runs `stop-force` twice.
   - The first cuts the power.
   - The second succeeds on a VM that is already off.
5. **`down`** runs `down`.
   - The domain is gone.
   - `left` lists only the data disk.
   - The image stays.
6. **`up-after-down`** runs `up` again. The token is still there, so `up` uses the data disk again instead of creating a new one.
7. **`delete-all`** runs `delete-all`.
   - The domain is gone.
   - `left` is `-`, so the pool and its directory are gone.
   - The image stays.
8. **`delete-all-after-down`** runs `create`, `down`, `delete-all`, then `down` once more.
   - `left` is `-`, so `delete-all` finds and deletes the data disk that `down` left, as #6 needed.
   - The last `down` succeeds on a VM that does not exist.

## In CI

The workflow installs libvirt on the runner and runs the test there in two cases:

- **For a tag:** before the image is published.
- **When it is run by hand:** from the Actions tab.

The libvirt of the runner cannot load the AppArmor profile of a VM, so the VMs run there without AppArmor. A change to the files that a VM opens also needs a run on a host with AppArmor, such as Debian or Ubuntu.
