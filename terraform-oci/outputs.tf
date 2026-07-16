output "instance_id" {
  description = "OCID of the OCI VPN instance."
  value       = oci_core_instance.vpn.id
}

output "reserved_ipv4" {
  description = "Reserved public IPv4 address used by Xray clients."
  value       = oci_core_public_ip.vpn.ip_address
}

output "selected_image" {
  description = "Ubuntu ARM image selected for the instance."
  value       = data.oci_core_images.ubuntu.images[0].display_name
}

output "free_tier_shape" {
  description = "Provisioned A1 shape allocation."
  value = var.instance_shape == "VM.Standard.A1.Flex" ? (
    "VM.Standard.A1.Flex: ${var.ocpus} OCPU, ${var.memory_in_gbs} GB RAM, ${var.boot_volume_size_in_gbs} GB boot volume"
    ) : (
    "VM.Standard.E2.1.Micro: fixed AMD micro shape, 1 GB RAM, ${var.boot_volume_size_in_gbs} GB boot volume"
  )
}

output "ansible_inventory_hint" {
  description = "Inventory entry for the first Ansible run on Canonical Ubuntu."
  value       = "vpn ansible_host=${oci_core_public_ip.vpn.ip_address} ansible_user=ubuntu"
}
