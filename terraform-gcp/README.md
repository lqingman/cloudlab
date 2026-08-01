# GCP VPN node (Tokyo) — short-term, credit-funded

A third node for the cloudlab stack, provisioned independently of the DigitalOcean and OCI
Terraform states. It exists because the OCI node is pinned to its Always Free home region
(Toronto, ~200–250 ms to China), which is unusable for video calls. Tokyo is 50–80 ms.

It provisions:

- one `e2-micro` Ubuntu 24.04 instance with Shielded VM enabled and no service account;
- a dedicated VPC, subnet, and two firewall rules (SSH + the Xray port) — not the default network;
- a **reserved static** public IPv4 address;
- a 10 GB `pd-standard` boot disk.

Ansible is unchanged: the same `xray` and `hardening` roles configure this node.

## Cost

Unlike the OCI node, **this one is billed**. GCP's Always Free `e2-micro` covers only
`us-west1`/`us-central1`/`us-east1`, and an American node defeats the purpose.

Rough Tokyo pricing, for a ten-day pre-trip soak plus a three-week trip:

| Item | Estimate (USD) |
| --- | --- |
| `e2-micro`, 31 days | ~$8 |
| Static IP attached to a running instance | ~$3.7 |
| 10 GB `pd-standard` | ~$0.4 |
| Egress, ~15 GB (see below) | ~$3 |
| **Total** | **~$15** |

Egress is billed per GB and China is a **premium destination** — roughly $0.23/GB outbound to
mainland China, about double the usual rate. Both directions of a proxied session cost something:
the VM→client leg bills at the China rate, the VM→destination leg at the ordinary rate.

In practice video calls are cheap. A 1:1 720p call is roughly 1.5–1.8 GB/hour across both
directions, which works out to **$0.20–0.35 per hour**. Streaming video is what burns credit; a
few hours of interviews is noise. Set a budget alert anyway.

Figures are approximate and regional prices change — confirm against the
[pricing calculator](https://cloud.google.com/products/calculator) before applying.

### Do not stop the instance to save money

Stopping saves the compute charge but **the boot disk is still billed, and a static IP costs more
when it is not attached to a running instance** ($0.010/hr detached vs $0.005/hr attached). Over
ten idle days the difference is about $1.30. Leaving it running is worth far more than that: it
gives you a window to re-test reachability from China before you depend on it.

## 1. Prepare

```bash
gcloud auth application-default login
gcloud config set project <project-id>
gcloud services enable compute.googleapis.com
```

## 2. Configure and review

```bash
cd terraform-gcp
cp terraform.tfvars.example terraform.tfvars   # fill in project_id + ssh_public_key
terraform init
terraform fmt -check
terraform validate
terraform plan
```

## 3. Create and configure

```bash
terraform apply
terraform output reserved_ipv4
terraform output ansible_inventory_hint
```

Add the inventory entry to `../ansible/inventory/hosts.ini` alongside the OCI host, then run the
existing playbook against it.

### Pick a Reality dest that works from this node

Do not assume the OCI node's `reality_dest` works here. The dest must complete a TLS 1.3 + HTTP/2
handshake **from this server** — `www.microsoft.com` fails from some networks because its CDN
negotiates down. Test candidates on the box before setting `reality_dest`/`reality_sni`:

```bash
for h in www.cloudflare.com www.shopify.com www.icloud.com www.bing.com; do printf '%-22s ' "$h"; timeout 5 openssl s_client -connect "$h:443" -servername "$h" -tls1_3 -alpn h2 </dev/null 2>/dev/null | grep -E '^(ALPN protocol|New,)' | tr '\n' ' '; echo; done
```

Both `TLSv1.3` and `ALPN protocol: h2` must be present. Prefer a different dest from the one the
OCI node uses, so a single blocked dest cannot take out both nodes.

## 4. Verify the address is not already blocked

Cloud IPv4 addresses are recycled, and a reused address may already be blacklisted. Check it from
mainland Chinese ISPs **before** relying on it:

```bash
terraform output reachability_check_hint
```

If it is unreachable, take a new address and re-test:

```bash
terraform apply -replace="google_compute_address.vpn" -replace="google_compute_instance.vpn"
```

A reserved address cannot be released while an instance holds it, so both are replaced together;
the rebuilt instance needs the Ansible run repeated. This costs almost nothing and is much cheaper
than discovering the problem from inside China.

Re-check every couple of days during the soak period. Reachability is a snapshot, not a guarantee.

## Caveats

- Keep the OCI node running as a fallback. The value of the pair is that two different providers in
  two different regions are unlikely to be blocked simultaneously — not that either is inherently
  safe.
- Blocking risk is driven mostly by individual address history and region popularity, not by which
  cloud you pick. Tokyo is scanned far more heavily than Toronto.
- `terraform destroy` releases the static IP. If you want to keep the address between trips, destroy
  only the instance and leave `google_compute_address.vpn` in place (it bills at the detached rate).
