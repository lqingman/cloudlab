# cloudlab — Personal VPN on DigitalOcean (Xray VLESS + Reality)

A personal censorship-circumvention node. Stack: DigitalOcean Droplet + Xray (VLESS + Reality) + the 3X-UI management panel.

> Full design notes are in [`docs/PLAN.md`](docs/PLAN.md). This README is the hands-on runbook.

## Why VLESS + Reality (not plain Shadowsocks)

Plain Shadowsocks is increasingly detectable by active probing and traffic fingerprinting. **VLESS + Reality** disguises traffic as a normal HTTPS connection to a real, popular website (e.g. microsoft.com), needs **no domain and no TLS certificate**, and resists active probing far better.

## Quick Start

### 1. Create a Droplet
- Image: **Ubuntu 24.04 LTS**
- Size: cheapest Basic / Regular, ~$4–6/mo (1 vCPU, 512MB–1GB)
- Region: **Singapore (SGP1)** or **San Francisco (SFO3)**
- Auth: **SSH public key** (generate locally first: `ssh-keygen -t ed25519 -C "vpn-do"`)

Note the assigned public IP.

### 2. Harden the server
After SSH-ing into the server, upload and run [`scripts/server-setup.sh`](scripts/server-setup.sh):

```bash
# Local: upload the script
scp scripts/server-setup.sh root@YOUR_IP:/root/

# Server: run it (creates a sudo user, hardens SSH, configures UFW, installs fail2ban)
ssh root@YOUR_IP
chmod +x server-setup.sh
./server-setup.sh
```

> ⚠️ The script disables SSH password login. **Confirm your SSH public key already works for passwordless login before running it**, or you may lock yourself out.

### 3. Install Xray + the 3X-UI panel
```bash
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
```
During install, change the panel **username / password / port / access path** (never keep the defaults).

Access the panel securely over an SSH tunnel (do not expose the panel port to the public internet):
```bash
# Local (assuming the panel port is 2053):
ssh -L 2053:localhost:2053 root@YOUR_IP
# Open http://localhost:2053 in your browser
```

In the panel, create an inbound:
- Protocol **VLESS** + security **Reality**
- dest/SNI: `www.microsoft.com:443` (any real HTTPS site reachable from your region)
- Port **443** → generate a `vless://` share link / QR code

### 4. Clients
| Platform | Client |
|----------|--------|
| Windows | v2rayN / Clash Verge Rev |
| macOS | V2rayU / Clash Verge Rev |
| iOS | Shadowrocket / Streisand |
| Android | v2rayNG / Nekobox |

Import the share link → connect → visit `ip.sb` to confirm your exit IP is now the Droplet's IP.

## Verification Checklist
- [ ] `systemctl status x-ui` runs cleanly
- [ ] `ufw status` allows only SSH + 443 (+ panel port, or local-only via tunnel)
- [ ] After connecting, `ip.sb` shows the Droplet IP
- [ ] `dnsleaktest.com` shows no DNS leak
- [ ] Works on both desktop and mobile

## Roadmap (resume-project direction)
See the end of [`docs/PLAN.md`](docs/PLAN.md): codify with Terraform/Ansible → CI/CD → Prometheus/Grafana monitoring → multi-user subscription system.

## Notes
~$4–6/mo. For personal, lawful use only — comply with the DigitalOcean ToS and local laws.
