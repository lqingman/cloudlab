# OCI Always Free VPN node

This Terraform stack creates a separate Oracle Cloud Infrastructure node without touching the
existing DigitalOcean Terraform state. It provisions:

- one `VM.Standard.A1.Flex` Ubuntu 24.04 ARM64 instance;
- a VCN, public subnet, internet gateway, route table, and edge security list;
- inbound TCP 22 for SSH and TCP 443 for Xray;
- a reserved public IPv4 address;
- a 50 GB boot volume.

Defaults are deliberately conservative: **1 OCPU and 2 GB RAM**. Variable validation prevents a
single deployment from exceeding the Always Free-only account cap of **2 OCPUs and 12 GB RAM**.
The 50 GB boot volume is part of OCI's 200 GB combined Always Free boot/block-volume allowance.
Existing OCI A1 instances and volumes still count toward the tenancy-wide limits, so check the OCI
Billing/Cost Analysis and Block Storage pages before applying.

## 1. Prepare OCI authentication

The provider reads the `DEFAULT` profile from `~/.oci/config`. In the OCI Console, open your user
profile, add an API key, download its private key, and copy the generated configuration preview to
`~/.oci/config`. The profile contains the tenancy OCID, user OCID, fingerprint, home region, and
private-key path. Keep the private key outside this repository.

## 2. Configure and review

```bash
cd terraform-oci
cp terraform.tfvars.example terraform.tfvars
# Fill in compartment_ocid, the HOME region, and your SSH public key.
terraform init
terraform fmt -check
terraform validate
terraform plan
```

Before applying, confirm the plan says `VM.Standard.A1.Flex`, no more than 2 OCPUs/12 GB, and a
50 GB boot volume. Terraform cannot determine how much Always Free capacity other resources in the
tenancy already consume.

## 3. Create and configure

```bash
terraform apply
terraform output reserved_ipv4
terraform output ansible_inventory_hint
```

Copy the inventory hint into `../ansible/inventory/hosts.ini`, then run the existing playbook. The
Canonical Ubuntu image initially uses the `ubuntu` SSH user:

```bash
cd ../ansible
ansible-galaxy collection install -r requirements.yml
ansible-playbook site.yml --ask-vault-pass
```

After testing the new client link, keep the OCI and DigitalOcean nodes running in parallel until the
OCI path is proven stable. Destroy the DigitalOcean stack only from the original `terraform/`
directory and only when you intentionally want to remove it.

## Always Free caveats

- Use the tenancy's **home region** and an Always Free-eligible Ubuntu image.
- An `Out of host capacity` response means the selected AD currently has no A1 capacity. Try another
  AD if available, or retry later.
- OCI may reclaim an Always Free instance it classifies as idle over a seven-day period. Keep the
  configuration reproducible and do not treat the VM as the only copy of important data.
- Oracle can change Free Tier terms. Recheck the official limits before every new deployment.
