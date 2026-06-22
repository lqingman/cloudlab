variable "do_token" {
  description = "DigitalOcean API token. Set via TF_VAR_do_token env var or terraform.tfvars (git-ignored)."
  type        = string
  sensitive   = true
}

variable "droplet_name" {
  description = "Hostname / name of the droplet."
  type        = string
  default     = "vpn-sgp"
}

variable "region" {
  description = "DigitalOcean region slug (e.g. sgp1, sfo3, ams3)."
  type        = string
  default     = "sgp1"
}

variable "droplet_size" {
  description = "Droplet size slug. Premium Intel 2 vCPU / 4 GB by default."
  type        = string
  default     = "s-2vcpu-4gb-intel"
}

variable "droplet_image" {
  description = "Base image slug."
  type        = string
  default     = "ubuntu-24-04-x64"
}

variable "ssh_public_key" {
  description = "Contents of your SSH public key (the .pub file). Used to create the DO SSH key."
  type        = string
}

variable "ssh_key_name" {
  description = "Name for the SSH key registered in DigitalOcean."
  type        = string
  default     = "cloudlab-key"
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to reach SSH (port 22). Restrict to your IP for better security; defaults to anywhere."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "xray_port" {
  description = "Public TCP port the Xray VLESS+Reality inbound listens on."
  type        = number
  default     = 443
}

variable "tags" {
  description = "Tags applied to the droplet (used by the firewall and project grouping)."
  type        = list(string)
  default     = ["cloudlab", "vpn"]
}
