variable "pve_endpoint" {
  type    = string
  default = "https://10.0.20.10:8006/"
}

variable "image_url" {
  description = "Pinned, dated Ubuntu 24.04 cloud image (not /current/)"
  type        = string
}

variable "image_checksum" {
  description = "SHA256 from the same release's SHA256SUMS"
  type        = string
}

variable "ssh_public_key" {
  type = string
}

variable "ci_username" {
  type    = string
  default = "ansible"
}

variable "bridge" {
  type    = string
  default = "vmbr0"
}

variable "vlan_id" {
  description = "null if vmbr0 is not VLAN-aware / untagged for LAB"
  type        = number
  default     = 20
  nullable    = true
}

variable "gateway" {
  type    = string
  default = "10.0.20.1"
}

variable "dns_servers" {
  description = "Router, not Pi-hole: infrastructure stays off Pi-hole"
  type        = list(string)
  default     = ["10.0.20.1"]
}
