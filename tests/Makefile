.DELETE_ON_ERROR:
MAKEFLAGS += --no-builtin-rules --no-builtin-variables --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -euo pipefail -c
.NOTPARALLEL:

E2E_URI ?= qemu:///system
E2E_IMAGE ?= virtgen
E2E_RUN ?= podman run --rm --userns=keep-id
E2E_TIMEOUT ?= 900

NAME := virtgen-e2e
IMAGE := debian-cloud-13-amd64.qcow2
WORK := $(abspath work)
PROV := $(WORK)/provisioners/$(NAME)
export LIBVIRT_DEFAULT_URI := $(E2E_URI)
export SSH_EXTRA_OPTS := -o LogLevel=ERROR

STEPS := render up stop-and-up stop-force down up-after-down delete-all delete-all-after-down
.PHONY: all clean $(STEPS)

all: $(STEPS) clean

# The provisioner runs as a user runs it, without the flags of this make.
vm = env MAKEFLAGS= $(MAKE) -s -C $(PROV) LIBVIRT_DEFAULT_URI='$(E2E_URI)'
ready = timeout $(E2E_TIMEOUT) $(vm) wait-for-ready
state = virsh domstate $(NAME) 2>/dev/null | sed '/^$$/d' || echo missing
image = virsh vol-info --pool default $(IMAGE) >/dev/null 2>&1 && echo kept || echo gone
read_token = $(vm) ssh CMD='sudo head -c 32 /dev/disk/by-id/virtio-data'
# Once down has undefined the pool of the VM, its directory can still hold volumes, so a transient
# pool on the directory lists them.
define left
if virsh pool-info $(NAME) >/dev/null 2>&1; then t=; else \
  virsh pool-refresh default >/dev/null; \
  if ! virsh vol-info --pool default $(NAME) >/dev/null 2>&1; then echo -; exit 0; fi; \
  virsh pool-create $(PROV)/pools/$(NAME).xml >/dev/null; t=1; \
fi; \
virsh pool-refresh $(NAME) >/dev/null; \
virsh vol-list $(NAME) | awk 'NR > 2 && $$1 { print $$1 }' | sort | paste -sd ' ' -; \
if [ -n "$$t" ]; then virsh pool-destroy $(NAME) >/dev/null; fi
endef
# $(call expect,CHECK,COMMAND,VALUE): fails unless COMMAND prints VALUE.
expect = @v=$$($(2)); if [ "$$v" = "$(3)" ]; then echo 'ok: $(1)'; \
  else echo 'FAIL: $(1): expected "$(3)", got "'"$$v"'"' >&2; exit 1; fi

render:
	@if virsh dominfo $(NAME) >/dev/null 2>&1 || virsh pool-info $(NAME) >/dev/null 2>&1; then \
	  echo '$(NAME) exists on $(E2E_URI). make clean deletes it if a run of this test left it.' >&2; exit 1; \
	fi
	rm -rf $(WORK)
	mkdir -p $(WORK)/provisioners
	$(E2E_RUN) -v $(CURDIR)/registry:/mnt/registry -v $(WORK)/provisioners:/mnt/provisioners $(E2E_IMAGE) \
	  > $(WORK)/render.log 2>&1 || { cat $(WORK)/render.log >&2; exit 1; }

up:
	$(vm) up
	$(ready)
	$(call expect,the VM runs,$(state),running)
	$(call expect,up creates the volumes of the VM,$(left),$(NAME)-boot.qcow2 $(NAME)-data.qcow2 $(NAME)-seed.iso)
	$(call expect,ssh runs a CMD of two lines,$(vm) ssh CMD="$$(printf '%s\n' 'echo "$$HOME"' 'echo two')" | paste -sd ' ' -,/home/debian two)
	od -An -N16 -tx1 /dev/urandom | tr -d ' \n' > $(WORK)/token
	$(vm) ssh CMD="printf %s $$(cat $(WORK)/token) | sudo dd of=/dev/disk/by-id/virtio-data conv=fsync status=none"

stop-and-up:
	$(vm) stop
	$(call expect,stop shuts the guest down,$(state),shut off)
	$(vm) up
	$(ready)
	$(call expect,the data disk keeps what the guest wrote,$(read_token),$$(cat $(WORK)/token))

stop-force:
	$(vm) stop-force
	$(call expect,stop-force cuts the power,$(state),shut off)
	$(vm) stop-force

down:
	$(vm) down
	$(call expect,down deletes the domain,$(state),missing)
	$(call expect,down keeps only the Reusable data disk,$(left),$(NAME)-data.qcow2)
	$(call expect,down keeps the Shared image,$(image),kept)

up-after-down:
	$(vm) up
	$(ready)
	$(call expect,up uses the data disk again,$(read_token),$$(cat $(WORK)/token))

delete-all:
	$(vm) delete-all
	$(call expect,delete-all deletes the domain,$(state),missing)
	$(call expect,delete-all deletes the pool and its directory,$(left),-)
	$(call expect,delete-all keeps the Shared image,$(image),kept)

delete-all-after-down:
	$(vm) create
	$(vm) down
	$(vm) delete-all
	$(call expect,delete-all after down deletes the data disk and the directory,$(left),-)
	$(vm) down

clean:
	if [ -e $(PROV)/Makefile ]; then $(vm) delete-all; fi
	rm -rf $(WORK)
