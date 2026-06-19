# Roadmap & Budget

How this personal VPN grows into a coherent, résumé-worthy infrastructure project — and what it
costs. The guiding principle: **one project with depth beats many shallow ones.** Every layer below
hangs off a single story: *a self-hosted, observable, infrastructure-as-code, cloud-portable VPN.*

## Guiding constraint: portability over lock-in

The DigitalOcean GitHub Student Pack credit expires **2026-07-31**, so the node migrates to another
provider before then. Therefore:

- **Long-lived components use portable tech** (Docker, Kubernetes, Prometheus, Terraform) so they
  survive the migration unchanged.
- **DO-proprietary managed services** (App Platform, Managed Databases, Spaces) are treated as
  *spin-up-this-month, learn, document, tear down* experiments — paid for by the free credit, never
  on the critical path.

This itself is a résumé point: "evaluated self-hosted vs. managed trade-offs and kept the
architecture provider-agnostic for a planned migration."

---

## Capability layers

Each layer is independently shippable and maps to concrete résumé skills.

### L0 — Working VPN + hardening *(in progress)*
- Xray (VLESS + Reality) on Ubuntu 24.04; key-only SSH, UFW, fail2ban.
- **Skills:** Linux administration, SSH hardening, firewalls, TLS/Xray.

### L1 — Infrastructure as Code *(highest value-per-effort; do this first after L0)*
- **Terraform** provisions the Droplet + **DO Cloud Firewall** + **Reserved IP** (a floating IP so
  the public IP survives rebuilds).
- **Ansible** automates everything `scripts/server-setup.sh` does, plus the Xray install/config.
- Goal: rebuild the entire node from scratch with one command.
- **Skills:** Terraform, Ansible, IaC, idempotency, immutable infrastructure.

### L2 — Observability *(the "what to monitor" layer)*
- Self-hosted **Prometheus + Grafana + Alertmanager** via `docker-compose` on the primary droplet
  (portable; later movable to Kubernetes).
- See the monitoring design below.
- **Skills:** Prometheus, Grafana, PromQL, alerting/SLOs, SRE thinking.

### L3 — Containerization & orchestration *(résumé highlight; uses the free credit well)*
- Containerize the panel/monitoring; push images to **DOCR** (DO Container Registry).
- Run the monitoring stack on **DOKS** (DO managed Kubernetes). Kubernetes for a single-user VPN is
  deliberately over-engineered — but as a *learning* exercise it is high-value and fully portable.
- **Skills:** Docker, Kubernetes, Helm, container orchestration.

### L4 — Application layer & CI/CD *(optional, time-permitting)*
- **GitHub Actions:** push → `terraform apply` / redeploy; secrets via GitHub Secrets.
- Small web dashboard (multi-user, subscription links, usage quotas) backed by a database — a good
  excuse to trial **DO Managed Postgres**.
- **Skills:** CI/CD, full-stack, REST APIs, managed databases.

### L5 — Migration *(by 2026-07-31)*
- Add a second provider to Terraform (Vultr for better China routing, or Oracle Cloud Always Free).
- Deploy on the new platform, cut over clients, destroy the DO node before the credit expires.
- **Skills:** multi-cloud, zero/low-downtime migration, capacity planning.

---

## Monitoring design (L2 detail)

What a VPN service is worth monitoring, and how to collect it:

| Dimension | What to track | Tool |
|-----------|---------------|------|
| Host health | CPU, memory, disk, load | `node_exporter` |
| Network throughput | in/out rate, connection count | `node_exporter` |
| Service liveness | Is the Xray process up? Is :443 reachable? | `blackbox_exporter` + process check |
| VPN business metrics | active connections, per-user up/down traffic | Xray stats API / 3X-UI data |
| External availability | reachability + latency probed from outside | `blackbox_exporter` (TCP/ICMP) |
| Security | failed SSH logins, fail2ban bans, auth anomalies | logs + `fail2ban` exporter |
| **Cost / quota** | **bandwidth used vs. plan allowance** (overage = $) | DO API + small custom exporter |
| Alerting | node down / high CPU / quota near limit → notify | **Alertmanager → Telegram/email** |

**The two strongest stories to build and document:**
1. **Bandwidth-quota alerting** — alert at ~80% of the transfer allowance to avoid overage billing.
   Demonstrates cost awareness.
2. **Availability SLO** — external blackbox probing with a 99.x% target and automated alerting.
   Demonstrates SRE thinking.

**Starting point:** run `Prometheus + Grafana + node_exporter + blackbox_exporter + Alertmanager`
with `docker-compose` on the primary droplet first (stands up in ~an hour with off-the-shelf Grafana
dashboards). Move it to DOKS later for the L3 milestone — the stack is portable, so the move *is*
the lesson.

---

## Budget

The $200 credit makes **this month effectively free**. Two numbers matter: the **steady-state
run-rate** (what you pay after migration) and the **this-month experiment burn** (covered by credit).

### Steady-state core (keep running)

| Item | Spec | ~Cost/mo |
|------|------|----------|
| **Primary droplet** | Premium Intel, **2 vCPU / 4 GB / 80 GB** (SGP1 has Intel only) | **~$32** |
| Cloud Firewall | — | free |
| Reserved IP | (free while attached) | free |
| DO Monitoring (native) | — | free |
| **Core total** | runs VPN **and** the full monitoring stack | **~$32/mo** |

> A single $32 droplet handles the VPN + Prometheus/Grafana/exporters comfortably; included transfer
> (~4–5 TB) is far more than a personal VPN uses. After migration you can stay at $32 or downsize the
> VPN-only node to ~$14 and run monitoring elsewhere.

### How DigitalOcean billing works (so the plan is correct)

- Resources accrue **hourly**, capped at the listed monthly price. **Not charged upfront** — you are
  **invoiced at the end of each month** for actual usage.
- The **$200 credit is drawn down as usage accrues**, applied against each invoice until exhausted
  **or expired**. Unused credit does not roll over and has no penalty — it simply expires.
- The hard wall is the **expiry date: 2026-07-31**. The only number that matters is total accrued
  usage ≤ $200 before then.

### What's free vs. what consumes credit

- **Free:** Cloud Firewalls, VPC, DO native Monitoring + alerts, DNS hosting, Container Registry
  (starter tier), Kubernetes **control plane** (standard/non-HA), Reserved IP *(free only while
  attached to a running droplet)*.
- **Paid (consumes credit):** Droplets, DOKS **worker nodes**, Managed Databases (~$15+/mo), Load
  Balancers (~$12/mo), Spaces ($5/mo), Backups (~20% of droplet), bandwidth **overage**
  ($0.01/GB), GPU droplets (expensive).

### Credit Maximization Plan — goal: spend close to $200, never exceed it

Usable window: **2026-06-19 → 2026-07-31 ≈ 42 days (~1.4 months)** — spans a partial June + full
July, but only ~6 weeks of clock time. Target **~$155 total** with a safety buffer under $200.

**June 19–30 (12 days) — build the core, spend almost nothing (~$13)**

| Item | Rate | 12-day cost |
|------|------|-------------|
| Primary droplet (Premium Intel, 2 vCPU / 4 GB) | $32/mo | ~$13 |
| Firewall / DNS / Monitoring / Reserved IP | free | $0 |

Do L0 (VPN working) → L1 (Terraform/Ansible) → L2 (monitoring) here, cheaply.

**July 1–30 (30 days) — full production-grade setup, burn the rest (~$152)**

| Item | ~$/mo |
|------|-------|
| Primary droplet (continues, Premium Intel 4 GB) | $32 |
| 2 extra regional VPN nodes (SFO3 + AMS3) | ~$30 |
| DOKS cluster (2 worker nodes; control plane free) | ~$48 |
| Managed Postgres (smallest) | ~$15 |
| Load Balancer | ~$12 |
| Spaces + CDN | ~$5 |
| Bandwidth overage buffer | ~$10 |

**Total ≈ $165** (June ~$13 + July ~$152), leaving **~$35 headroom** under $200. To push toward ~$185, add a 3rd DOKS worker
(+$24) or a Postgres standby (+$30) in July — but keep ≥$15 buffer; overshooting $200 bills the
real card.

### Two hard rules (or you pay out of pocket)

1. **Destroy all paid resources by 2026-07-30** (`terraform destroy` once coded — the clean version
   of the story). Anything alive after July 31 bills your card.
2. **Check the billing dashboard weekly** (DO shows remaining credit); set a billing alert at $180.
