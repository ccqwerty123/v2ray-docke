#!/bin/sh
set -e

# --- 辅助函数 (保持不变) ---
validate_uuid() {
  if ! echo "$1" | grep -Eq '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'; then
    echo "错误: 您提供的 UUID '$1' 格式不正确。" >&2
    exit 1
  fi
}

validate_domain() {
  if ! echo "$1" | grep -Eq '^[a-zA-Z0-9][a-zA-Z0-9.-]*\.[a-zA-Z]{2,}$'; then
    echo "错误: 获取到的域名 '$1' 格式不正确。" >&2
    return 1
  fi
  return 0
}

# --- 主要逻辑 (调用 xray) ---

# 1. 确定域名 (逻辑不变)
FINAL_DOMAIN=""
DEFAULT_DOMAIN="pull.free.video.10010.com"
# ... (省略域名获取的详细代码，保持和上一版完全一样) ...
if [ -n "$V2RAY_DOMAIN_URL" ]; then
  echo "INFO: 尝试从 URL ($V2RAY_DOMAIN_URL) 获取域名..." >&2
  FETCHED_DOMAIN=$(wget -qO- --timeout=5 --tries=1 "$V2RAY_DOMAIN_URL" | xargs)
  if [ -n "$FETCHED_DOMAIN" ] && validate_domain "$FETCHED_DOMAIN"; then
    FINAL_DOMAIN="$FETCHED_DOMAIN"; echo "INFO: 成功从 URL 获取并验证域名: $FINAL_DOMAIN" >&2
  else
    echo "WARNING: 无法从 URL 获取有效域名，将尝试下一优先级。" >&2
  fi
fi
if [ -z "$FINAL_DOMAIN" ] && [ -n "$V2RAY_DOMAIN" ]; then
  echo "INFO: 尝试使用环境变量 V2RAY_DOMAIN..." >&2
  if validate_domain "$V2RAY_DOMAIN"; then
    FINAL_DOMAIN="$V2RAY_DOMAIN"; echo "INFO: 成功验证域名: $FINAL_DOMAIN" >&2
  else
    echo "ERROR: 环境变量中的域名 '$V2RAY_DOMAIN' 格式无效。" >&2; exit 1
  fi
fi
if [ -z "$FINAL_DOMAIN" ]; then
  FINAL_DOMAIN="$DEFAULT_DOMAIN"
  echo "INFO: 未提供任何域名信息，将使用内置默认域名: $FINAL_DOMAIN" >&2
fi

# 2. 确定 UUID (逻辑不变)
DEFAULT_UUID="33809cd4-3095-447d-db67-0e607dd23d5b"
if [ -n "$V2RAY_UUID" ]; then
  validate_uuid "$V2RAY_UUID"
  FINAL_UUID="$V2RAY_UUID"
else
  FINAL_UUID="$DEFAULT_UUID"
fi

# --- 生成配置并启动服务 (关键变化: 使用 xray) ---

# 使用 xray 命令生成密钥对和 UUID
KEY_PAIR=$(/usr/bin/xray x25519)
PRIVATE_KEY=$(echo "$KEY_PAIR" | grep 'Private key' | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEY_PAIR" | grep 'Public key' | awk '{print $3}')

# sed 替换逻辑不变
sed -e "s/__UUID__/$FINAL_UUID/g" \
    -e "s/__PRIVATE_KEY__/$PRIVATE_KEY/g" \
    -e "s/__DOMAIN__/$FINAL_DOMAIN/g" \
    config.template.json > config.json

# --- 输出最终信息 (逻辑不变，输出的标题依然可以是 V2Ray，方便用户理解) ---
VLESS_URL="vless://${FINAL_UUID}@YOUR_SERVER_IP:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${FINAL_DOMAIN}&fp=chrome&pbk=${PUBLIC_KEY}&type=tcp#Xray_REALITY_$(date +%s)"

echo ""
echo "===================================================================="
echo "          Xray (V2Ray-Compatible) VLESS REALITY 节点启动成功！"
echo "===================================================================="
# ... (省略详细参数的输出，保持和上一版完全一样) ...
echo "详细参数:"
echo "--------------------------------------------------------------------"
echo "地址 (Address):      请填写您的服务器IP或已解析的域名"
echo "端口 (Port):         443"
echo "用户ID (UUID):       $FINAL_UUID"
echo "流控 (Flow):         xtls-rprx-vision"
echo "安全 (Security):     reality"
echo "SNI (Server Name):   $FINAL_DOMAIN"
echo "指纹 (Fingerprint):  chrome"
echo "公钥 (Public Key):   $PUBLIC_KEY"
echo "路径 (Path):         (无, REALITY模式不使用路径)"
echo "--------------------------------------------------------------------"
echo ""
echo ">>> VLESS 导入链接 (请复制并替换 YOUR_SERVER_IP):"
echo "--------------------------------------------------------------------"
echo "$VLESS_URL"
echo "--------------------------------------------------------------------"
echo ""
echo "             警告: 请务必将链接中的 'YOUR_SERVER_IP'             "
echo "               替换为您的服务器公网 IP 地址后使用！             "
echo ""
echo "===================================================================="
echo "Xray-core 核心正在启动..."
echo ""

# 最终执行 xray run 命令
exec /usr/bin/xray run -config /etc/v2ray/config.json
