# Résumé Material

Draft bullets and talking points distilled from [`PROJECT-LOG.md`](PROJECT-LOG.md). Refine the
metrics as the project progresses — replace every _(TODO)_ with a real number or fact.

## One-line project title

> **Self-hosted VPN with Infrastructure-as-Code and zero-downtime cloud migration**

## Résumé bullets (tighten once metrics are real)

- Designed and deployed a personal VPN on a Linux cloud VPS using **Xray (VLESS + Reality)**,
  chosen over Shadowsocks for stronger resistance to active probing and traffic fingerprinting;
  hardened the server with key-only SSH, **UFW**, and **fail2ban**.
- Automated the full provisioning and configuration pipeline with **Terraform** (infrastructure)
  and **Ansible** (configuration management), reducing a from-scratch rebuild from _(TODO: ~X min
  manual)_ to a single command.
- Built the system to be **cloud-portable** and migrated it across providers
  (DigitalOcean → _(target)_) with _(TODO: X%)_ of the IaC reused and _(TODO: ~X min)_ of downtime,
  ahead of a hard credit-expiry deadline.

## Talking points (for interviews)

- **Why VLESS + Reality, not Shadowsocks?** Trade-offs in detectability vs. simplicity.
- **Why IaC?** Reproducibility, fast rebuild after an IP gets blocked, and provider portability.
- **The migration story.** A real, deadline-driven reason the architecture had to be portable —
  shows planning, not just tool familiarity.
- **Security choices.** Key-only SSH, least-privilege firewall, panel never exposed publicly
  (SSH-tunnel only).

## Skills demonstrated

Linux administration · Cloud (DigitalOcean / _(target)_) · **Terraform** · **Ansible** ·
networking & TLS · security hardening · _(later: CI/CD, Prometheus/Grafana)_

## Links

- Repo: _(TODO: GitHub URL)_
- Architecture & runbook: [`../README.md`](../README.md), [`PLAN.md`](PLAN.md)
