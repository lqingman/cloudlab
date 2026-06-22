terraform {
  required_version = ">= 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.40"
    }
  }

  # For a real team setup you would use a remote backend (e.g. DO Spaces, S3,
  # or Terraform Cloud). For this personal project the state stays local and is
  # git-ignored. Migration to a remote backend is a documented roadmap item.
  # backend "s3" { ... }
}

provider "digitalocean" {
  token = var.do_token
}
