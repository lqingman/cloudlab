#!/usr/bin/env bash
#
# server-setup.sh — Base security hardening for a DigitalOcean Droplet (Ubuntu 24.04)
#
# What it does: creates a normal sudo user, hardens SSH (key-only login),
# configures the UFW firewall, and installs fail2ban.
# Run as root:  ./server-setup.sh
#
# WARNING: This script disables SSH password login. Before running, make sure your
#          SSH public key already works for passwordless login, or you may lock
#          yourself out. The script copies root's authorized_keys to the new user.

set -euo pipefail

# ---- tunable variables ----
NEW_USER="${NEW_USER:-deploy}"     # name of the new normal user
SSH_PORT="${SSH_PORT:-22}"         # SSH port (if changed, UFW is updated to match)
XRAY_PORT="${XRAY_PORT:-443}"      # Xray inbound port
# ---------------------------

if [[ "${EUID}" -ne 0 ]]; then
  echo "Please run as root: sudo ./server-setup.sh" >&2
  exit 1
fi

echo "==> 1/6 System update"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

echo "==> 2/6 Install base tools (ufw, fail2ban, curl)"
apt-get install -y ufw fail2ban curl

echo "==> 3/6 Create normal user: ${NEW_USER}"
if ! id -u "${NEW_USER}" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" "${NEW_USER}"
  usermod -aG sudo "${NEW_USER}"
  # Passwordless sudo (convenient for a personal node; remove for stricter setups)
  echo "${NEW_USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-${NEW_USER}"
  chmod 440 "/etc/sudoers.d/90-${NEW_USER}"
else
  echo "User ${NEW_USER} already exists, skipping creation."
fi

echo "==> 4/6 Copy SSH public key to ${NEW_USER}"
if [[ -f /root/.ssh/authorized_keys ]]; then
  install -d -m 700 -o "${NEW_USER}" -g "${NEW_USER}" "/home/${NEW_USER}/.ssh"
  install -m 600 -o "${NEW_USER}" -g "${NEW_USER}" \
    /root/.ssh/authorized_keys "/home/${NEW_USER}/.ssh/authorized_keys"
  echo "Key copied. Test 'ssh ${NEW_USER}@<IP>' for passwordless login before dropping root."
else
  echo "WARNING: /root/.ssh/authorized_keys not found — pick SSH-key auth when creating the Droplet." >&2
  echo "         Configure a key for ${NEW_USER} BEFORE disabling password login, or you'll be locked out!" >&2
fi

echo "==> 5/6 Harden SSH (disable root password login, disable password auth)"
SSHD_CFG="/etc/ssh/sshd_config.d/99-hardening.conf"
cat > "${SSHD_CFG}" <<EOF
Port ${SSH_PORT}
PermitRootLogin prohibit-password
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
EOF
# Validate config before restarting
sshd -t
systemctl restart ssh || systemctl restart sshd

echo "==> 6/6 Configure UFW firewall"
ufw default deny incoming
ufw default allow outgoing
ufw allow "${SSH_PORT}"/tcp comment 'SSH'
ufw allow "${XRAY_PORT}"/tcp comment 'Xray'
ufw --force enable
ufw status verbose

# fail2ban monitors sshd by default
systemctl enable --now fail2ban

echo ""
echo "============================================================"
echo "Hardening complete."
echo ""
echo "Next steps:"
echo "  1) In a NEW terminal, test: ssh ${NEW_USER}@<this-IP>  (confirm passwordless login works)"
echo "  2) Install the 3X-UI panel:"
echo "     bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)"
echo "  3) If the panel port is not 443, reach it via an SSH tunnel — do not expose it publicly."
echo "============================================================"
