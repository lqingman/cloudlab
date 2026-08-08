terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# Authentication comes from Application Default Credentials (`gcloud auth
# application-default login`) so no service-account key material enters
# Terraform variables or state.
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
