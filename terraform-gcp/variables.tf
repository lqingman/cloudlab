variable "project_id" {
  description = "GCP project ID the VPN node is billed to. Credits are consumed from this project's billing account."
  type        = string
}

variable "region" {
  description = "GCP region. asia-northeast1 (Tokyo) gives the lowest latency to mainland China; asia-southeast1 (Singapore) is an alternative for southern China."
  type        = string
  default     = "asia-northeast1"
}

variable "zone" {
  description = "Zone within the region. Must belong to var.region."
  type        = string
  default     = "asia-northeast1-b"
}

variable "instance_name" {
  description = "Instance name, also used as the hostname and as a prefix for network resources."
  type        = string
  default     = "cloudlab-vpn-gcp"
}

variable "machine_type" {
  description = "Compute Engine machine type. e2-micro is ample for Xray; note that GCP's Always Free e2-micro applies only to us-west1/us-central1/us-east1, so an Asian region is billed."
  type        = string
  default     = "e2-micro"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size. Billed while the instance is stopped as well as running."
  type        = number
  default     = 10

  validation {
    condition     = var.boot_disk_size_gb >= 10 && floor(var.boot_disk_size_gb) == var.boot_disk_size_gb
    error_message = "boot_disk_size_gb must be a whole number of at least 10 GB."
  }
}

variable "boot_disk_type" {
  description = "Persistent disk type. pd-standard is the cheapest and is fast enough for a proxy node."
  type        = string
  default     = "pd-standard"

  validation {
    condition     = contains(["pd-standard", "pd-balanced", "pd-ssd"], var.boot_disk_type)
    error_message = "boot_disk_type must be pd-standard, pd-balanced, or pd-ssd."
  }
}

variable "network_tier" {
  description = "Egress network tier. PREMIUM routes over Google's private backbone and measurably improves China routing; STANDARD is cheaper per GB but takes the public internet."
  type        = string
  default     = "PREMIUM"

  validation {
    condition     = contains(["PREMIUM", "STANDARD"], var.network_tier)
    error_message = "network_tier must be PREMIUM or STANDARD."
  }
}

variable "ssh_public_key" {
  description = "Contents of the SSH public key installed for the ubuntu user."
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "IPv4 CIDRs allowed to reach SSH. Restrict this to your current public IP when possible."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "xray_port" {
  description = "Public TCP port used by the Xray VLESS+Reality inbound."
  type        = number
  default     = 443

  validation {
    condition     = var.xray_port >= 1 && var.xray_port <= 65535 && floor(var.xray_port) == var.xray_port
    error_message = "xray_port must be a whole number from 1 to 65535."
  }
}
