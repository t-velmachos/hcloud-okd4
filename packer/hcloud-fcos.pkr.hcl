packer {
  required_plugins {
    hcloud = {
      version = ">= 1.1.1"
      source  = "github.com/hetznercloud/hcloud"
    }
  }
}
variable "hcloud_token" {
  type      = string
  default   = env("HCLOUD_TOKEN")
  sensitive = true
}
variable "location" {
  type      = string
  default   = "hel1"
}
variable "server_type" {
  type      = string
  default   = "cx22"
}
variable "snapshot_prefix" {
  type      = string
  default   = "fcos"
}
variable "image_type" {
  type      = string
  default   = "generic"
}
variable "ignition_config" {
  type      = string
  default   = "config-3.3.0.ign"
}

# Source for the CoreOS x86 snapshot
source "hcloud" "fcos-x86-snapshot" {
  image       = "ubuntu-22.04"
  rescue      = "linux64"
  location    = var.location
  server_type = var.server_type
  snapshot_labels = {
    fcos-snapshot = "yes"
    creator = "tvelmachos"
    os = "fcos"
    image_type = var.image_type
  }
  snapshot_name = "Fedora CoreOs"
  ssh_username  = "root"
  token         = var.hcloud_token
}

# Build the FCOS x86 snapshot
build {
  sources = ["source.hcloud.fcos-x86-snapshot"]
  # Download the FCOS x86 image
  provisioner "shell" {
    inline = [
        "set -x",
        "mkdir /source",
        "mount -t tmpfs -o size=2G none /source",
        "cd /source",
        "curl -sfL https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/39.20231101.3.0/x86_64/fedora-coreos-39.20231101.3.0-qemu.x86_64.qcow2.xz | unxz > fedora-coreos-qemu.x86_64.qcow2",
        "qemu-img convert fedora-coreos-qemu.x86_64.qcow2 -O raw /dev/sda",
        "partprobe /dev/sda",
        "mkdir /target",
        "mount /dev/sda3 /target",
        "mkdir /target/ignition"
    ]
  }

  # Write the FCOS x86 image to disk
  provisioner "file" {
    source = var.ignition_config
    destination = "/target/ignition/config.ign"
  }

  # Ensure connection to FCOS x86 and do house-keeping
  provisioner "shell" {
    inline  = ["set -x", "cd /", "umount /source", "umount /target"]
  }

}
