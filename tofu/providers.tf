provider "proxmox" {
  endpoint = var.pve_endpoint
  insecure = true # self-signed PVE cert, revisit if you build internal PKI

  # Token comes from the PROXMOX_VE_API_TOKEN env var and is never committed.
}
