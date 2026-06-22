output "droplet_id" {
  description = "ID of the VPN droplet."
  value       = digitalocean_droplet.vpn.id
}

output "droplet_ipv4" {
  description = "Direct public IPv4 of the droplet."
  value       = digitalocean_droplet.vpn.ipv4_address
}

output "reserved_ipv4" {
  description = "Stable reserved IP assigned to the droplet — use THIS as the server address in clients."
  value       = digitalocean_reserved_ip.vpn.ip_address
}

output "droplet_ipv6" {
  description = "Public IPv6 of the droplet."
  value       = digitalocean_droplet.vpn.ipv6_address
}

# Convenience: a ready-to-use Ansible inventory line for this host.
output "ansible_inventory_hint" {
  description = "Paste into ansible/inventory/hosts.ini (use the reserved IP)."
  value       = "vpn ansible_host=${digitalocean_reserved_ip.vpn.ip_address} ansible_user=root"
}
