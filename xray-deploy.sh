#!/bin/bash
# Xray VLESS+Reality 一键部署 (Ubuntu 20.04)
# 自动生成新密钥
set -e

echo "[1/4] 安装 Xray..."
apt update -qq && apt install -y -qq curl
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

echo "[2/4] 生成密钥..."
KEYS=$(xray x25519)
PK=$(echo "$KEYS" | head -1 | awk '{print $NF}')
PBK=$(echo "$KEYS" | tail -1 | awk '{print $NF}')
UI=$(xray uuid)
SI=$(openssl rand -hex 4)

echo "  Private Key: $PK"
echo "  Public Key:  $PBK"
echo "  UUID:        $UI"
echo "  Short ID:    $SI"

echo "[3/4] 写入配置..."
cat > /usr/local/etc/xray/config.json << EOFCONF
{
  "log": {"loglevel": "warning"},
  "inbounds": [{
    "listen": "0.0.0.0",
    "port": 443,
    "protocol": "vless",
    "settings": {
      "clients": [{"email": "u1", "id": "${UI}", "flow": "xtls-rprx-vision"}],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "show": false,
        "dest": "www.microsoft.com:443",
        "xver": 0,
        "serverNames": ["www.microsoft.com"],
        "privateKey": "${PK}",
        "shortIds": ["${SI}"]
      },
      "tcpSettings": {"header": {"type": "none"}}
    },
    "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
  }],
  "outbounds": [
    {"protocol": "freedom", "tag": "direct"},
    {"protocol": "blackhole", "tag": "blocked"}
  ],
  "routing": {
    "rules": [{"type": "field", "ip": ["geoip:private"], "outboundTag": "blocked"}]
  }
}
EOFCONF

echo "[4/4] 启动 Xray..."
systemctl enable xray && systemctl restart xray
sleep 2

STATUS=$(systemctl is-active xray)
echo ""
echo "=========================================="
echo "  Xray 状态: $STATUS"
echo "  Public Key: $PBK"
echo "  UUID:       $UI"
echo "  Short ID:   $SI"
echo "=========================================="
