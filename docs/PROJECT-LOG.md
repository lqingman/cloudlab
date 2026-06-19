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

## (todo) Phase 1: working node on DigitalOcean

- [ ] Create Ubuntu 24.04 Droplet (Singapore), SSH-key auth
- [ ] Run `server-setup.sh` (sudo user, key-only SSH, UFW, fail2ban)
- [ ] Install 3X-UI, create a VLESS+Reality inbound on :443
- [ ] Verify: exit IP changes, no DNS leak, works on desktop + mobile
- [ ] _Log here: how long it took, any gotchas (e.g. region latency, panel access)_

## (todo) Phase 2: Infrastructure as Code

- [ ] Terraform: provision the Droplet + firewall (DigitalOcean provider)
- [ ] Ansible: automate everything `server-setup.sh` does, plus Xray install/config
- [ ] One-command rebuild from scratch; document the runbook
- [ ] _Log here: what you'd do differently, what the automation saved_

## (todo) Phase 3: migration (by end of July 2026)

- [ ] Pick target: Vultr (better China routing) or Oracle Cloud Always Free (free forever)
- [ ] Add the new provider to Terraform; deploy node on the new platform
- [ ] Cut over clients; verify; destroy the DigitalOcean node before the credit expires
- [ ] _Log here: how much of the IaC was reusable, total migration time_
