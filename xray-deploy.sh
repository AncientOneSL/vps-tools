#!/bin/bash
# Xray VLESS+Reality 一键部署 (Ubuntu 20.04)
set -e

echo "[1/3] 安装 Xray..."
apt update -qq && apt install -y -qq curl
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

echo "[2/3] 写入配置..."
cat > /usr/local/etc/xray/config.json << 'EOF'
{
  "log": {"loglevel": "warning"},
  "inbounds": [{
    "listen": "0.0.0.0",
    "port": 443,
    "protocol": "vless",
    "settings": {
      "clients": [{"email": "u1", "id": "5fc7434d-929d-4580-a34d-422d0399fc8b", "flow": "xtls-rprx-vision"}],
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
        "privateKey": "8kus84x8PIEL6kWTOsaLsh-JnolZ3Y7ZIaSOHFFFVX0",
        "shortIds": ["940dce2e"]
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
EOF

echo "[3/3] 启动 Xray..."
systemctl enable xray && systemctl restart xray
sleep 2

echo ""
echo "========== 部署完成 =========="
echo "Xray 状态: $(systemctl is-active xray)"
echo "Public Key: _-gA7lPsNpPh5DJWacVX7XheAgCgwk7u6MbhfVaygSs"
echo "UUID: 5fc7434d-929d-4580-a34d-422d0399fc8b"
echo "Short ID: 940dce2e"
echo "=============================="
