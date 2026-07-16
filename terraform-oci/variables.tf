variable "oci_config_profile" {
  description = "Profile in ~/.oci/config used by the OCI provider."
  type        = string
  default     = "DEFAULT"
}

variable "compartment_ocid" {
  description = "OCI compartment OCID. The tenancy OCID can be used for the root compartment."
  type        = string
}

variable "region" {
  description = "OCI home-region identifier, for example ap-singapore-1. Always Free resources must be created in the home region."
  type        = string
}

variable "availability_domain_number" {
  description = "One-based availability-domain number. Try another value if OCI reports out of host capacity."
  type        = number
  default     = 1

  validation {
    condition     = var.availability_domain_number >= 1 && floor(var.availability_domain_number) == var.availability_domain_number
    error_message = "availability_domain_number must be a positive whole number."
  }
}

variable "instance_name" {
  description = "Display name and hostname for the OCI VPN instance."
  type        = string
  default     = "cloudlab-vpn-oci"
}

variable "instance_shape" {
  description = "Always Free compute shape. E2.1.Micro is fixed AMD/1 GB; A1.Flex uses the configurable limits below."
  type        = string
  default     = "VM.Standard.A1.Flex"

  validation {
    condition     = contains(["VM.Standard.A1.Flex", "VM.Standard.E2.1.Micro"], var.instance_shape)
    error_message = "instance_shape must be VM.Standard.A1.Flex or VM.Standard.E2.1.Micro."
  }
}

variable "ocpus" {
  description = "Ampere A1 OCPUs. Always Free-only accounts allow at most 2 OCPUs total across all A1 instances."
  type        = number
  default     = 1

  validation {
    condition     = var.ocpus >= 1 && var.ocpus <= 2 && floor(var.ocpus) == var.ocpus
    error_message = "ocpus must be a whole number from 1 to 2 to remain within the Always Free-only limit."
  }
}

variable "memory_in_gbs" {
  description = "Ampere A1 memory. Always Free-only accounts allow at most 12 GB total across all A1 instances."
  type        = number
  default     = 2

  validation {
    condition     = var.memory_in_gbs >= 1 && var.memory_in_gbs <= 12
    error_message = "memory_in_gbs must be between 1 and 12 to remain within the Always Free-only limit."
  }
}

variable "boot_volume_size_in_gbs" {
  description = "Boot volume size. OCI Always Free includes 200 GB total across all boot and block volumes."
  type        = number
  default     = 50

  validation {
    condition     = var.boot_volume_size_in_gbs >= 50 && var.boot_volume_size_in_gbs <= 200
    error_message = "boot_volume_size_in_gbs must be from 50 to 200 GB. Account for any other OCI volumes before increasing it."
  }
}

variable "ssh_public_key" {
  description = "Contents of the SSH public key installed for the Ubuntu user."
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
