# Project Log

A running log of milestones, decisions, and what was learned — the raw material for the
résumé bullets in [`RESUME.md`](RESUME.md). Add a dated entry whenever something meaningful happens.

> Dates use `YYYY-MM-DD`. Keep entries factual: what changed, why, and what you learned.

---

## 2026-06 — Phase 0: design & repo scaffolding

- Decided on **Xray VLESS + Reality** over plain Shadowsocks (better resistance to active
  probing / traffic fingerprinting; no domain or TLS cert required).
- Chose the **3X-UI panel** for the first working version: fast to stand up, and its web UI is a
  natural foundation for a later management/monitoring layer.
- Scaffolded the repo: `README.md` runbook, `docs/PLAN.md` design notes, `scripts/server-setup.sh`
  hardening script, `.gitignore` for secrets.
- Learned the constraint that shapes the whole project: the DigitalOcean GitHub Student Pack
  credit **expires 2026-07-31**, so the architecture must be portable from day one.

## 2026-06-19 — Phase 1: working node on DigitalOcean ✅

- [x] Created Ubuntu 24.04 Droplet in Singapore (SGP1), Premium Intel 2 vCPU / 4 GB, SSH-key auth.
- [x] Ran `server-setup.sh`: created `deploy` sudo user, disabled SSH password login (key-only),
      configured UFW (allow 22 + 443 only), enabled fail2ban. Verified passwordless login + sudo
      before relying on key-only auth (no lockout).
- [x] Installed 3X-UI panel (v3.3.1, Xray 26.6.1). Panel port is **not** opened in UFW by design —
      reached only via SSH local-forward tunnel (`ssh -L`), never exposed publicly.
- [x] Created a VLESS + Reality inbound on :443 (dest/SNI `www.microsoft.com`, flow
      `xtls-rprx-vision`, auto-generated keypair + shortIds).
- [x] Verified end-to-end: client (v2rayN on Windows) connects, ~200 ms RTT Canada→Singapore,
      exit IP becomes the Droplet IP, browsing works.

**Gotchas / debugging story (the real learning):**
- An inbound with **no client** has no usable credential — the share link is empty until a client
  (UUID) is added.
- Adding a client in the panel UI wrote it to the DB but did **not** hot-reload Xray; the running
  `config.json` still had `clients: null`, so Xray rejected the handshake with
  `invalid request user id`. Fix: force a regen/reload with `x-ui restart`.
- Direct SQLite edits to the inbound's `settings` are **not** picked up by config generation —
  changes must go through the panel/service layer.
- The panel exported the link with `@localhost` (because the panel was accessed over the SSH
  tunnel); had to substitute the real public IP.
- Diagnosis method worth reusing: isolate client vs. server by running a local Xray client on the
  server itself (loopback to :443) with `loglevel: debug` — the server-side log pinpointed the
  exact rejection reason.

**Follow-up housekeeping:**
- Kernel was upgraded during `apt upgrade` → `*** System restart required ***`. Reboot when
  convenient (x-ui is enabled for autostart and comes back on its own). Rebooting drops active
  client connections briefly.

## 2026-06-21 — Phase 2: Infrastructure as Code (L1) — scaffolding ✅, deploy test pending

- [x] Terraform module (`terraform/`): droplet + DO cloud firewall (SSH + Xray only) + reserved IP
      + SSH key + project. Parameterized via variables; `terraform validate` passes (v1.15.5).
- [x] Ansible (`ansible/`): `hardening` role (sudo user, key-only SSH drop-in, UFW, fail2ban) and
      `xray` role (xray-core install + **declaratively templated** `config.json` for VLESS+Reality —
      no panel, fully reproducible). Config validated via `xray run -test` in the template task.
- [x] `scripts/gen-link.sh` to build client `vless://` links (no panel in the IaC path).
- [x] Decision: IaC path drops 3X-UI in favor of a templated `config.json` to avoid the mutable
      panel/DB state that bit us in Phase 1.
- [ ] **Pending: end-to-end test** — apply on a throwaway droplet, run the playbook, verify, then
      `terraform destroy`. Doubles as a rehearsal for the end-of-July migration.
- [ ] _Log after test: what broke, what the automation saved vs. manual._

**Execution note:** Terraform runs on Windows natively; Ansible needs a Linux control node — run it
under **WSL** or from CI (Linux runner) in the L2 DevSecOps step.

## (todo) Phase 3: migration (by end of July 2026)

- [ ] Pick target: Vultr (better China routing) or Oracle Cloud Always Free (free forever)
- [ ] Add the new provider to Terraform; deploy node on the new platform
- [ ] Cut over clients; verify; destroy the DigitalOcean node before the credit expires
- [ ] _Log here: how much of the IaC was reusable, total migration time_
