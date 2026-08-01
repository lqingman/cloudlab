# Infrastructure as Code (L1) — Terraform + Ansible

Provision and configure a complete VPN node from scratch with two commands. This is the
reproducible, version-controlled replacement for the manual Phase 1 steps and
`scripts/server-setup.sh`.

```
terraform/   # provisions the droplet, cloud firewall, reserved IP, SSH key, project
terraform-oci/ # provisions a separate OCI Always Free A1 node for migration/testing
ansible/     # hardens the host + installs & configures Xray (VLESS + Reality)
```

## Design decisions

- **No control panel in the IaC path.** Ansible templates `/usr/local/etc/xray/config.json`
  directly, so the config is the single source of truth and 100% reproducible. (The 3X-UI panel on
  the hand-built node remains handy for ad-hoc user management, but introduces mutable state we
  don't want in IaC.)
- **Cloud firewall + host UFW** (defense in depth): DO's firewall filters at the edge, UFW on the
  host. Both allow only SSH + the Xray port.
- **Reserved IP** so the public address survives a droplet rebuild — clients don't need
  reconfiguring after `terraform destroy`/`apply`.
- **Secrets never committed**: Terraform reads the DO token from `TF_VAR_do_token`; Ansible secrets
  live in a vault-encrypted `group_vars/all.yml`. Only `*.example` files are tracked.

## Prerequisites

- **Terraform** ≥ 1.5 (runs natively on Windows).
- **Ansible** (control node must be Linux/macOS/**WSL** — Ansible doesn't run natively on Windows).
  On Windows: run everything under WSL, or run Ansible from CI (a Linux runner) in the L2 step.
- A DigitalOcean API token, and your SSH keypair.

## 1. Provision infrastructure (Terraform)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # then fill in token + ssh_public_key
terraform init
terraform plan
terraform apply
terraform output                                # note reserved_ipv4
```

## 2. Configure the node (Ansible)

```bash
cd ../ansible
ansible-galaxy collection install -r requirements.yml

cp inventory/hosts.ini.example inventory/hosts.ini     # set the reserved IP
cp group_vars/all.yml.example group_vars/all.yml       # fill in secrets, then:
#   generate values:
#     uuid:   cat /proc/sys/kernel/random/uuid
#     keys:   xray x25519        (locally, or on any host with xray)
#     short:  openssl rand -hex 8
ansible-vault encrypt group_vars/all.yml

ansible-playbook site.yml --ask-vault-pass
```

### OCI Always Free alternative

To create an OCI node without changing or destroying the DigitalOcean Terraform state, follow
[`terraform-oci/README.md`](../terraform-oci/README.md). Its defaults are 1 A1 OCPU, 2 GB RAM, and a
50 GB boot volume, with validation caps at the Always Free-only limits of 2 OCPUs and 12 GB RAM.

## 3. Build a client link

The IaC node has no panel, so generate the `vless://` link from your values:

```bash
SERVER_IP=<reserved ip> UUID=<xray_uuid> PBK=<reality public key> SID=<short id> \
  SNI=<reality_sni> ../scripts/gen-link.sh
```

`SNI` must match `reality_sni` in `group_vars/all.yml` exactly — the script's default
(`www.microsoft.com`) is not necessarily what the node is running.

## 4. Client apps

The inbound is **VLESS + Reality with `flow=xtls-rprx-vision`**, so a client needs to support both
Reality *and* the Vision flow. Plain "V2Ray" clients that predate Reality won't work.

| Platform | Client | Notes |
| --- | --- | --- |
| Windows | v2rayN | Xray-core based; the reference client for this stack. |
| macOS | v2rayN, or Shadowrocket (Mac App Store) | |
| Android | v2rayNG | Same core, same link format. |
| iOS | **Streisand** (free) or **Shadowrocket** ($2.99) | Both Xray-core based. sing-box also works but is config-file oriented. |

iOS notes: these apps are delisted from the China App Store, so a non-CN Apple ID is required.
Import by copying the `vless://` link to the clipboard (the app offers to add it) or by scanning a
QR code — `gen-link.sh` output pipes straight into `qrencode -t ANSIUTF8`.

After importing on any client, verify three fields survived the parse — some clients silently drop
them, which produces a connection that handshakes but behaves badly:

- `flow` = `xtls-rprx-vision`
- `fp` = `chrome` (the uTLS fingerprint Reality's disguise depends on)
- `sni` = the node's `reality_sni`

Then confirm egress actually goes through the node by checking your public IP against the reserved
IP. If it still shows your local address, the client is in rule mode and routing that traffic
direct — retest in global mode.

## Testing without touching the live node

Spin up a throwaway droplet with this exact code, verify end-to-end, then `terraform destroy`.
This both proves the automation and rehearses the **end-of-July migration** (the credit-expiry
deadline) — at which point the same code redeploys the node on a new provider/region by changing a
few variables.

## Next (DevSecOps roadmap)

- **CI security gates**: `tfsec`/`checkov` (Terraform), `ansible-lint`, `gitleaks` in GitHub Actions.
- **Observability**: Prometheus + Grafana + exporters.
- **Threat detection**: Cowrie honeypot + CrowdSec, with attack-data analysis.
