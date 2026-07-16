locals {
  vcn_cidr    = "10.42.0.0/16"
  subnet_cidr = "10.42.1.0/24"
}

data "oci_identity_availability_domains" "available" {
  compartment_id = var.compartment_ocid
}

# Select the newest Canonical Ubuntu 24.04 image compatible with the chosen
# Always Free shape. OCI returns ARM64 for A1.Flex and x86_64 for E2.1.Micro.
data "oci_core_images" "ubuntu" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_vcn" "vpn" {
  compartment_id = var.compartment_ocid
  cidr_block     = local.vcn_cidr
  display_name   = "${var.instance_name}-vcn"
  dns_label      = "cloudlab"
}

resource "oci_core_internet_gateway" "vpn" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vpn.id
  display_name   = "${var.instance_name}-internet-gateway"
  enabled        = true
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vpn.id
  display_name   = "${var.instance_name}-public-routes"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.vpn.id
  }
}

resource "oci_core_security_list" "vpn" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vpn.id
  display_name   = "${var.instance_name}-security-list"

  dynamic "ingress_security_rules" {
    for_each = toset(var.allowed_ssh_cidrs)
    content {
      protocol  = "6"
      source    = ingress_security_rules.value
      stateless = false

      tcp_options {
        min = 22
        max = 22
      }
    }
  }

  ingress_security_rules {
    protocol  = "6"
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = var.xray_port
      max = var.xray_port
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    stateless   = false
  }
}

resource "oci_core_subnet" "public" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.vpn.id
  cidr_block                 = local.subnet_cidr
  display_name               = "${var.instance_name}-public-subnet"
  dns_label                  = "vpn"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.vpn.id]
}

resource "oci_core_instance" "vpn" {
  availability_domain  = data.oci_identity_availability_domains.available.availability_domains[var.availability_domain_number - 1].name
  compartment_id       = var.compartment_ocid
  display_name         = var.instance_name
  shape                = var.instance_shape
  preserve_boot_volume = false

  dynamic "shape_config" {
    for_each = var.instance_shape == "VM.Standard.A1.Flex" ? [1] : []
    content {
      ocpus         = var.ocpus
      memory_in_gbs = var.memory_in_gbs
    }
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  create_vnic_details {
    assign_public_ip = false
    display_name     = "${var.instance_name}-primary-vnic"
    hostname_label   = "vpn"
    subnet_id        = oci_core_subnet.public.id
  }

  metadata = {
    ssh_authorized_keys = trimspace(var.ssh_public_key)
  }

  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }

  freeform_tags = {
    project = "cloudlab"
    service = "vpn"
  }

  lifecycle {
    precondition {
      condition     = length(data.oci_core_images.ubuntu.images) > 0
      error_message = "No compatible Ubuntu 24.04 ARM image was found in this region."
    }

    precondition {
      condition     = var.availability_domain_number <= length(data.oci_identity_availability_domains.available.availability_domains)
      error_message = "availability_domain_number is larger than the number of availability domains in this region."
    }
  }
}

data "oci_core_vnic_attachments" "vpn" {
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.vpn.id
}

data "oci_core_private_ips" "vpn" {
  vnic_id = data.oci_core_vnic_attachments.vpn.vnic_attachments[0].vnic_id
}

# A reserved public IP survives instance replacement as long as Terraform does
# not destroy this resource. It is attached to the instance's primary private IP.
resource "oci_core_public_ip" "vpn" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.instance_name}-reserved-ip"
  lifetime       = "RESERVED"
  private_ip_id  = data.oci_core_private_ips.vpn.private_ips[0].id
}
