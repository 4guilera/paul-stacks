locals {
  # Topology is code, so it's committed. VM IDs mirror IPs (like pihole 130/131).
  nodes = {
    k3s1 = {
      vm_id    = 170
      pve_node = "pve-node2"
      role     = "server"
      ip       = "10.0.20.70"
      cores    = 2
      memory   = 4096
      disk_gb  = 30
    }
    k3s2 = {
      vm_id    = 171
      pve_node = "pve-node1"
      role     = "agent"
      ip       = "10.0.20.71"
      cores    = 4
      memory   = 8192
      disk_gb  = 60
    }
  }

  pve_nodes = toset([for n in local.nodes : n.pve_node])
}

# `local` is directory storage, so each node needs its own copy of the image.
resource "proxmox_download_file" "ubuntu_noble" {
  for_each = local.pve_nodes

  node_name          = each.key
  datastore_id       = "local"
  content_type       = "import"
  url                = var.image_url
  file_name          = "noble-server-cloudimg-amd64.qcow2" # import rejects .img; it's qcow2 inside
  checksum           = var.image_checksum
  checksum_algorithm = "sha256"
}

resource "proxmox_virtual_environment_vm" "k3s" {
  for_each = local.nodes

  name        = each.key
  node_name   = each.value.pve_node
  vm_id       = each.value.vm_id
  description = "k3s ${each.value.role} - managed by OpenTofu (paul-stacks)"
  tags        = ["k3s", each.value.role]

  on_boot         = true
  stop_on_destroy = true # no guest agent yet; don't hang waiting on graceful shutdown

  startup {
    order = 3 # after DNS (order=1)
  }

  machine       = "q35"
  scsi_hardware = "virtio-scsi-single" # required for iothread

  cpu {
    cores = each.value.cores
    type  = "x86-64-v3" # both Ryzens support it; portable, unlike "host"
  }

  memory {
    dedicated = each.value.memory # no ballooning: kubelet hates shrinking RAM
  }

  agent {
    enabled = false # Ansible installs qemu-guest-agent in step 3, then flip to true
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    import_from  = proxmox_download_file.ubuntu_noble[each.value.pve_node].id
    size         = each.value.disk_gb
    iothread     = true
    discard      = "on"
    ssd          = true
  }

  network_device {
    bridge  = var.bridge
    vlan_id = var.vlan_id
  }

  # Ubuntu cloud images kernel-panic on boot-disk resize without a serial device.
  serial_device {
    device = "socket"
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = var.gateway
      }
    }

    dns {
      servers = var.dns_servers
    }

    user_account {
      username = var.ci_username
      keys     = [var.ssh_public_key]
    }
  }
}
