output "nodes" {
  description = "Feeds the Ansible inventory in step 3"
  value = {
    for k, v in local.nodes : k => {
      ip       = v.ip
      role     = v.role
      pve_node = v.pve_node
    }
  }
}
