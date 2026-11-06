packer {
  required_plugins {
    ansible = {
      version = " >= 1.0.4"
      source  = "github.com/hashicorp/ansible"
    }
    openstack = {
      version = " >= 1.1.2"
      source  = "github.com/hashicorp/openstack"
    }
  }
}

variable "env" {
  type    = string
  default = "dev"
}

locals {
  env_network_id = var.env == "prod" ? "5be315b7-7ebd-4254-97fe-18c1df501538" : "fa2f5ebe-d0e0-4465-9637-e9461de443f1"
  date_suffix = "${formatdate("YYYY-MM-DD", timestamp())}"
  metadata = {
    "hw_machine_type" : "q35",
    "hw_disk_bus" : "scsi",
    "hw_qemu_guest_agent" : "yes",
    "hw_scsi_model" : "virtio-scsi",
    "hw_vif_multiqueue_enabled" : "true",
    "os_require_quiesce" : "yes",
    "os_admin_user": "cloud",
    # This must be set to BIOS to avoid problems where NVIDIA drivers expect BAR support
    # (as we are in EFI mode) but our host HVs are still in BIOS mode.
    # "NVRM: This PCI I/O region assigned to your NVIDIA device is invalid:"
    # "NVRM: BAR0 is 0M @ 0x0", where the BAR offered is a 0MB region so obviously invalid.
    # Once we're RL9 + EFI + Above 4GB decoding everywhere we can enable EFI which gives
    # some perf benefits for GPU passthrough where REBAR can be used
    "hw_firmware_type" : "bios",
    "image_builder_version": "0.3.2"
  }
  aq_metadata = {
    "AQ_ARCHETYPE": "cloud",
    "AQ_DOMAIN": "prod",
    "aq_managed": "true",
    "AQ_OS": "rocky",
    "AQ_OSNAME": "rocky",
    "AQ_PERSONALITY": "nubesvms",
  }
}

source "openstack" "builder" {
  domain_name       = "Default"
  flavor            = "l3.imagecreate"
  security_groups   = ["default"]
  networks          = ["${local.env_network_id}"]
  image_visibility  = "private"
  ssh_timeout       = "20m"
  image_min_disk    = "20"
}

build {
  source "openstack.builder" {
    name                      = "ubuntu-jammy-22.04-nogui"
    image_name                = "ubuntu-jammy-22.04-nogui-${ local.date_suffix }"
    ssh_username              = "ubuntu"
    external_source_image_url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
    metadata = local.metadata
  }
  source "openstack.builder" {
    name                      = "ubuntu-noble-24.04-nogui"
    image_name                = "ubuntu-noble-24.04-nogui-${ local.date_suffix }"
    ssh_username              = "ubuntu"
    external_source_image_url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    metadata = local.metadata
  }
  source "openstack.builder" {
    name                      = "ubuntu-resolute-26.04-nogui"
    image_name                = "ubuntu-resolute-26.04-nogui-preview-${ local.date_suffix }"
    ssh_username              = "ubuntu"
    external_source_image_url = "https://cloud-images.ubuntu.com/resolute/current/resolute-server-cloudimg-amd64.img"
    metadata = local.metadata
  }
  source "openstack.builder" {
    name = "rocky-8-nogui"
    image_name = "rocky-8-nogui-${ local.date_suffix }"
    ssh_username = "rocky"
    external_source_image_url = "https://www.mirrorservice.org/sites/download.rockylinux.org/pub/rocky/8/images/x86_64/Rocky-8-GenericCloud-Base.latest.x86_64.qcow2"
    metadata = local.metadata
  }
  source "openstack.builder" {
    name = "rocky-9-nogui"
    image_name = "rocky-9-nogui-${ local.date_suffix }"
    ssh_username = "rocky"
    external_source_image_url = "https://www.mirrorservice.org/sites/download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
    metadata = local.metadata
  }
  source "openstack.builder" {
    name = "rocky-10-nogui"
    image_name = "rocky-10-nogui-preview-${ local.date_suffix }"
    ssh_username = "rocky"
    external_source_image_url = "https://www.mirrorservice.org/sites/download.rockylinux.org/pub/rocky/10/images/x86_64/Rocky-10-GenericCloud-Base.latest.x86_64.qcow2"
    metadata = local.metadata
  }
  source "openstack.builder" {
    name = "rocky-8-aq"
    image_name = "rocky-8-aq-${ local.date_suffix }"
    ssh_username = "rocky"
    external_source_image_url = "https://www.mirrorservice.org/sites/download.rockylinux.org/pub/rocky/8/images/x86_64/Rocky-8-GenericCloud-Base.latest.x86_64.qcow2"
    metadata                  = merge(local.metadata, local.aq_metadata, {"AQ_OSVERSION": "8"})
  }
  source "openstack.builder" {
    name = "rocky-9-aq"
    image_name = "rocky-9-aq-${ local.date_suffix }"
    ssh_username = "rocky"
    external_source_image_url = "https://www.mirrorservice.org/sites/download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
    metadata                  = merge(local.metadata, local.aq_metadata, {"AQ_OSVERSION": "9"})
  }
  source "openstack.builder" {
    name = "rocky-10-aq"
    image_name = "rocky-10-aq-${ local.date_suffix }"
    ssh_username = "rocky"
    external_source_image_url = "https://www.mirrorservice.org/sites/download.rockylinux.org/pub/rocky/10/images/x86_64/Rocky-10-GenericCloud-Base.latest.x86_64.qcow2"
    metadata                  = merge(local.metadata, local.aq_metadata, {"AQ_OSVERSION": "10"})
  }

  sources = ["openstack.builder"]

  provisioner "ansible" {
    only = ["openstack.rocky-8-aq", "openstack.rocky-9-aq"]
    user          = "${build.User}"
    playbook_file = "playbooks/quattor.yml"
    extra_arguments = [
      # Still required for Rocky 8 and 9
      "--scp-extra-args", "'-O'",
    ]
  }

  provisioner "ansible" {
    user          = "${build.User}"
    playbook_file = "playbooks/configure_os_images.yml"
    extra_arguments = [
      # Workaround https://github.com/hashicorp/packer/issues/12416
      # This is required for Ubuntu (Debian) 24.04+ as SFTP is disabled by default
      "--scp-extra-args", "'-O'",
    ]
  }
}

