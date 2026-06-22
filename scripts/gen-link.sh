#!/usr/bin/env bash
#
# gen-link.sh — build a vless:// share link from the Ansible-managed Xray settings.
# The IaC node has no control panel, so this is how you produce client links/QRs.
#
# Usage:
#   SERVER_IP=203.0.113.10 \
#   UUID=... PBK=<reality public key> SID=<short id> SNI=www.microsoft.com \
#   ./gen-link.sh
#
# Then paste the printed link into v2rayN / v2rayNG / Shadowrocket.

set -euo pipefail

: "${SERVER_IP:?set SERVER_IP}"
: "${UUID:?set UUID (xray_uuid)}"
: "${PBK:?set PBK (reality public key)}"
: "${SID:?set SID (short id)}"
SNI="${SNI:-www.microsoft.com}"
PORT="${PORT:-443}"
NAME="${NAME:-cloudlab}"

echo "vless://${UUID}@${SERVER_IP}:${PORT}?type=tcp&encryption=none&security=reality&pbk=${PBK}&fp=chrome&sni=${SNI}&sid=${SID}&spx=%2F&flow=xtls-rprx-vision#${NAME}"
