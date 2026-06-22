locals {
  # Tag used to bind the firewall to the droplet.
  firewall_tag = "cloudlab-vpn"
}

# Register the SSH public key with DigitalOcean.
resource "digitalocean_ssh_key" "this" {
  name       = var.ssh_key_name
  public_key = var.ssh_public_key
}

# A tag we attach to the droplet so the firewall applies by tag (not by id),
# which keeps the firewall reusable across rebuilds.
resource "digitalocean_tag" "fw" {
  name = local.firewall_tag
}

# The VPN node.
resource "digitalocean_droplet" "vpn" {
  name       = var.droplet_name
  region     = var.region
  size       = var.droplet_size
  image      = var.droplet_image
  ipv6       = true
  monitoring = true
  ssh_keys   = [digitalocean_ssh_key.this.fingerprint]
  tags       = concat(var.tags, [digitalocean_tag.fw.name])
}

# Cloud firewall (defense-in-depth alongside the host UFW configured by Ansible).
# Inbound: SSH + the Xray port only. Outbound: everything.
resource "digitalocean_firewall" "vpn" {
  name = "${var.droplet_name}-fw"
  tags = [digitalocean_tag.fw.name]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.allowed_ssh_cidrs
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = tostring(var.xray_port)
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# A stable public IP that survives droplet rebuilds (free while assigned).
resource "digitalocean_reserved_ip" "vpn" {
  region = var.region
}

resource "digitalocean_reserved_ip_assignment" "vpn" {
  ip_address = digitalocean_reserved_ip.vpn.ip_address
  droplet_id = digitalocean_droplet.vpn.id
}

# Group everything under a DO Project for tidy organization.
resource "digitalocean_project" "cloudlab" {
  name        = "cloudlab"
  description = "Personal VPN infrastructure (IaC)"
  purpose     = "Web Application"
  environment = "Development"
  resources = [
    digitalocean_droplet.vpn.urn,
    digitalocean_reserved_ip.vpn.urn,
  ]
}
