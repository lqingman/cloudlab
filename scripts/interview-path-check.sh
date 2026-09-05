#!/bin/bash
# 面试链路体检。在面试时段(01:00-02:00)跑,结果追加到 ~/interview-path.log
# 用法:  bash scripts/interview-path-check.sh          # 只测链路
#         bash scripts/interview-path-check.sh --call   # 通话已接通时,额外查媒体路径
LOG="$HOME/interview-path.log"
exec > >(tee -a "$LOG") 2>&1
echo
echo "=============== $(date '+%Y-%m-%d %H:%M:%S %Z') ==============="
echo "10808 出口: $(curl -s --max-time 25 -x http://127.0.0.1:10808 https://ifconfig.me)"
echo "10877 出口: $(curl -s --max-time 25 -x http://127.0.0.1:10877 https://ifconfig.me)"
echo

# --- 1. 三条路 × 各目标,6 次采样全部列出(重点看尾部,不是最快值) ---
samples(){ o=""; for i in 1 2 3 4 5 6; do
    v=$(curl -so /dev/null --max-time 25 "$@" -w '%{time_appconnect}' 2>/dev/null)
    case "$v" in ""|0.000000) o="$o  失败";; *) o="$o $(printf '%5.2f' "$v")";; esac
  done; echo "$o"; }

echo "--- TLS 握手完成耗时/秒,6 次全列(⚠️ 必须加 --noproxy,否则量的是本地代理) ---"
for t in "twilio-jp1|https://jp1.vss.twilio.com/" \
         "twilio-us1|https://us1.vss.twilio.com/" \
         "codesignal|https://app.codesignal.com/"; do
  n=${t%%|*}; u=${t##*|}
  printf "  %-11s 直连  %s\n" "$n" "$(samples --noproxy '*' "$u")"
  printf "  %-11s 东京  %s\n" "$n" "$(samples -x http://127.0.0.1:10808 "$u")"
  printf "  %-11s 多伦多 %s\n" "$n" "$(samples -x http://127.0.0.1:10877 "$u")"
done

# --- 2. 媒体路径(仅在通话接通、画面在动时有意义) ---
if [ "$1" = "--call" ]; then
  echo
  echo "--- Chrome 的 UDP(媒体流) ---"
  UDP=$(lsof -nP -iUDP 2>/dev/null | grep -i chrome | grep -v '127.0.0.1' | grep -v '\*:\*' | awk '{print $9}' | sort -u)
  if [ -z "$UDP" ]; then
    echo "  没有 UDP -> 媒体没走直连。可能回落进隧道,也可能一个人在通话里根本没发流。"
    echo "  去 chrome://webrtc-internals 看 bytesSent 是否在涨,才能区分这两种。"
  else
    echo "$UDP" | sed 's/^/  /'
  fi
  echo "--- Chrome 的 TCP(已建立),按目标聚合 ---"
  lsof -nP -a -iTCP -sTCP:ESTABLISHED 2>/dev/null | grep -i chrome \
    | awk '{print $9}' | sed 's/.*->//' | sort | uniq -c | sort -rn | head -15 | sed 's/^/  /'
  echo "--- 媒体对端在哪(前 3 个 UDP 目标) ---"
  for ip in $(echo "$UDP" | sed 's/.*->//' | cut -d: -f1 | grep -E '^[0-9]+\.' | sort -u | head -3); do
    echo "  --- $ip ---"
    curl -s --max-time 8 --noproxy '*' "https://ipinfo.io/$ip/json" | grep -E '"(city|region|country|org)"' | sed 's/^/    /'
  done
fi
echo "=============== 完 ==============="
