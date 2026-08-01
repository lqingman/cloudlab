output "instance_id" {
  description = "Self-link of the GCP VPN instance."
  value       = google_compute_instance.vpn.self_link
}

output "reserved_ipv4" {
  description = "Reserved public IPv4 address used by Xray clients."
  value       = google_compute_address.vpn.address
}

output "selected_image" {
  description = "Ubuntu image selected for the instance."
  value       = data.google_compute_image.ubuntu.name
}

output "ansible_inventory_hint" {
  description = "Inventory entry for the Ansible run. GCP's Ubuntu images use the ubuntu SSH user."
  value       = "vpn ansible_host=${google_compute_address.vpn.address} ansible_user=ubuntu"
}

output "reachability_check_hint" {
  description = "Verify from mainland Chinese ISPs that the address is not already blocked before relying on it."
  value       = "https://www.itdog.cn/tcping/${google_compute_address.vpn.address}:${var.xray_port}"
}
