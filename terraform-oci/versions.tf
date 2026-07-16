terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7.0"
    }
  }
}

# Authentication is read from ~/.oci/config. Keeping credentials out of
# Terraform variables prevents API private-key material from entering state.
provider "oci" {
  config_file_profile = var.oci_config_profile
  region              = var.region
}
