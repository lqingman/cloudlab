locals {
  subnet_cidr  = "10.43.1.0/24"
  network_tags = ["cloudlab-vpn"]
}

data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}

# A dedicated VPC rather than the project's default network: the default comes
# with permissive pre-seeded firewall rules (RDP, ICMP, internal any-any) that
# we do not want on an internet-facing node.
resource "google_compute_network" "vpn" {
  name                    = "${var.instance_name}-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vpn" {
  name          = "${var.instance_name}-subnet"
  network       = google_compute_network.vpn.id
  region        = var.region
  ip_cidr_range = local.subnet_cidr
}

resource "google_compute_firewall" "ssh" {
  name        = "${var.instance_name}-allow-ssh"
  network     = google_compute_network.vpn.name
  description = "SSH access for Ansible and administration."

  source_ranges = var.allowed_ssh_cidrs
  target_tags   = local.network_tags

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "xray" {
  name        = "${var.instance_name}-allow-xray"
  network     = google_compute_network.vpn.name
  description = "Public Xray VLESS+Reality inbound."

  source_ranges = ["0.0.0.0/0"]
  target_tags   = local.network_tags

  allow {
    protocol = "tcp"
    ports    = [tostring(var.xray_port)]
  }
}

# Reserved (static) address. An ephemeral IP is released when the instance is
# stopped, which would invalidate every client link; reserving it keeps the
# address stable across stop/start and rebuilds.
resource "google_compute_address" "vpn" {
  name         = "${var.instance_name}-ipv4"
  region       = var.region
  address_type = "EXTERNAL"
  network_tier = var.network_tier
}

resource "google_compute_instance" "vpn" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = local.network_tags

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = var.boot_disk_size_gb
      type  = var.boot_disk_type
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vpn.id

    access_config {
      nat_ip       = google_compute_address.vpn.address
      network_tier = var.network_tier
    }
  }

  # OS Login is disabled so the metadata key below is the authoritative
  # credential, matching how the DO and OCI nodes are reached by Ansible.
  metadata = {
    ssh-keys               = "ubuntu:${trimspace(var.ssh_public_key)}"
    enable-oslogin         = "FALSE"
    block-project-ssh-keys = "TRUE"
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  # No service account: the node never calls Google APIs, so it should not
  # carry a token that a compromise could reuse.
  service_account {
    scopes = []
  }

  labels = {
    project = "cloudlab"
    service = "vpn"
  }

  lifecycle {
    precondition {
      condition     = startswith(var.zone, var.region)
      error_message = "zone must be inside region."
    }
  }
}
