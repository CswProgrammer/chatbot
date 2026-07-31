#!/usr/bin/env bash
# One-time server bootstrap for OpenCloudOS / Tencent Lighthouse.
# Run as root on the server (OrcaTerm or SSH).
set -euo pipefail

APP_DIR="/var/www/chatbot"
REPO_URL="https://github.com/CswProgrammer/chatbot.git"
DEPLOY_PUBKEY="${DEPLOY_PUBKEY:-}"

echo "==> Install system packages"
if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
  dnf install -y nodejs git
fi

npm config set registry https://registry.npmjs.org/
corepack enable
corepack prepare pnpm@10.32.1 --activate

if ! command -v pm2 >/dev/null 2>&1; then
  npm install -g pm2
fi

pm2 startup systemd -u root --hp /root >/dev/null 2>&1 || true

echo "==> Configure deploy SSH key"
mkdir -p /root/.ssh
chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

if [[ -n "$DEPLOY_PUBKEY" ]] && ! grep -qF "$DEPLOY_PUBKEY" /root/.ssh/authorized_keys; then
  echo "$DEPLOY_PUBKEY" >> /root/.ssh/authorized_keys
fi

echo "==> Clone application"
mkdir -p /var/www
if [[ ! -d "$APP_DIR/.git" ]]; then
  git clone "$REPO_URL" "$APP_DIR"
fi

cd "$APP_DIR"
git fetch origin main
git checkout main
git reset --hard origin/main

if [[ ! -f "$APP_DIR/.env.local" ]]; then
  echo "ERROR: Missing $APP_DIR/.env.local"
  echo "Create it with AUTH_SECRET, DEEPSEEK_API_KEY, POSTGRES_URL, AUTH_URL before continuing."
  exit 1
fi

echo "==> Install & build"
export HUSKY=0
pnpm install --frozen-lockfile --ignore-scripts
pnpm run build

echo "==> Start PM2"
pm2 start deploy/ecosystem.config.cjs
pm2 save

echo "==> Configure nginx"
if [[ -d /etc/nginx/conf.d ]]; then
  cp deploy/nginx.conf /etc/nginx/conf.d/chatbot.conf
  nginx -t
  systemctl enable nginx
  systemctl restart nginx
fi

echo "==> Bootstrap complete"
echo "Visit: http://$(curl -4 -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
