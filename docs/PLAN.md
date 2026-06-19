# Personal VPN on DigitalOcean — Design & Plan

## Context

A personal "VPN" (Shadowsocks-VPS style) on DigitalOcean, primarily for **censorship circumvention**, used on Windows/Mac desktops and iOS/Android phones. The near-term goal is "just make it work," with the option to grow it into a larger resume project later.

Key technical decision: in 2026, plain Shadowsocks is relatively easy for censorship systems (e.g. the GFW) to detect via active probing and traffic fingerprinting. The strongest anti-blocking option today is **Xray's VLESS + Reality** — it disguises traffic as a normal HTTPS connection to a real, popular website (e.g. microsoft.com), needs **no domain and no TLS certificate**, and resists active probing far better than Shadowsocks.

To satisfy "just make it work" while keeping a clean upgrade path toward the resume project, this plan installs Xray via the **3X-UI panel**: fast to stand up, with a built-in web management UI that naturally becomes the foundation for the larger version.

---

## Phase 1 — Provision the server (DigitalOcean Droplet)

1. **Sign up for DigitalOcean** → a `.edu` email often qualifies for the GitHub Student Pack's $200 credit; check first.
2. **Create the Droplet:**
   - Image: **Ubuntu 24.04 LTS**
   - Size: cheapest **Basic / Regular, ~$4–6/mo** (1 vCPU, 512MB–1GB RAM)
   - Region (**important** for latency and blocking odds): prefer **Singapore (SGP1)** or **San Francisco (SFO3)**; you can spin up one in each, test latency, then destroy the slower one
   - Auth: **SSH public key** (more secure than password)
   - Hostname: anything, e.g. `vpn-sgp`
3. Record the assigned **public IP**.

> Note: DigitalOcean IP ranges are not the best China routes; latency may be mediocre but usually workable. To chase speed later, rotate the IP (DO supports destroy/recreate) or compare Vultr/BandwagonHost.

---

## Phase 2 — Server security hardening

After SSH login (`ssh root@YOUR_IP`), run `scripts/server-setup.sh`, which performs:

1. **System update**: `apt update && apt upgrade -y`
2. **Create a normal sudo user** (don't run as root long-term)
3. **Harden SSH**: disable password login, key-only (`PasswordAuthentication no`)
4. **UFW firewall**: allow SSH + Xray port (443), deny the rest
5. **fail2ban** against SSH brute force

Generate an SSH key locally (Windows PowerShell / Mac terminal):
```
ssh-keygen -t ed25519 -C "vpn-do"
```

---

## Phase 3 — Install Xray + 3X-UI panel (core)

Use the **3X-UI** panel (one-line installer; built-in web UI, multi-protocol, multi-user, traffic stats):

1. One-line install (on the server):
   ```
   bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
   ```
2. During install, set **panel username/password, port, and access path** (always change the defaults).
3. Allow the panel port in UFW, or more securely **access the panel only over an SSH tunnel** (no public exposure).
4. Log into the panel → **create an Inbound**:
   - Protocol: **VLESS**
   - Transport security: **Reality**
   - Borrowed target site (dest/SNI): a real, regionally-reachable HTTPS site, e.g. `www.microsoft.com:443`, `www.apple.com:443`
   - Port: **443**
   - The panel auto-generates the keypair, UUID, and shortId
5. Generate the **client share link / QR code** (`vless://...`) for each device.

> Simpler alternative (if you skip the panel): the official `Xray-install` script + a hand-written `config.json`. The panel is friendlier for beginners and a better starting point for the resume project.

---

## Phase 4 — Client configuration

Import the panel's `vless://` link or QR code into each client:

| Platform | Recommended client |
|----------|--------------------|
| Windows | **v2rayN** (or Nekoray / Clash Verge Rev) |
| macOS | **V2rayU** / **Clash Verge Rev** / Mihomo Party |
| iOS | **Shadowrocket** (paid, most stable) / Streisand (free) |
| Android | **v2rayNG** / Nekobox |

For each device: scan the QR or paste the link → connect → test.

---

## Verification (end-to-end)

1. **Server side**: `systemctl status x-ui` confirms the panel and Xray are running; `ufw status` confirms only the needed ports are open.
2. **Connectivity**: after connecting, visit `https://www.google.com`, or check `ip.sb` / `whatismyip` to confirm the exit IP is the Droplet's.
3. **DNS leak**: visit `dnsleaktest.com` to confirm no leak.
4. **Anti-probing sanity check**: confirm the Reality dest site itself opens normally from your region (the disguise only works if it does).
5. **Multi-device**: connect once from both a desktop and a phone.

---

## Roadmap (resume-project direction; out of scope for this phase)

The current phase is "just make it work," but the following directions can evolve into resume highlights, in recommended order:

1. **Infrastructure as Code (IaC)**: **Terraform** to create the Droplet + **Ansible** to automate all of Phase 2/3 → demonstrates DevOps/cloud-engineering skills. Keep the scripts in this Git repo.
2. **Automated deploy + CI/CD**: one-click deploy/rebuild via GitHub Actions; manage secrets with GitHub secrets.
3. **Management backend + monitoring**: build a Prometheus + Grafana traffic/online-user dashboard on top of 3X-UI data.
4. **Multi-user / subscription system**: self-hosted subscription links, usage quotas, expiry management (can grow into a full-stack app).
5. **High availability / multi-node**: multi-region Droplets + domain-based routing + health checks.

> Suggestion: get it working manually first (understand what each step does), **then** codify the manual steps with Terraform/Ansible — that way the IaC is correct and the resume story is clearest.

---

## Notes

- **Cost**: ~$4–6/mo; power off / destroy when unused to save money (destroying loses the IP).
- **Compliance**: follow the DigitalOcean ToS and local laws; personal, lawful use only.
- **Security**: never use default panel port/path/weak passwords; run `apt upgrade` regularly.
- **IP rebuild**: if the IP gets blocked, destroy and recreate — so codifying Phases 1/2 early pays off for fast rebuilds.
