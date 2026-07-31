#!/usr/bin/env bash
# Restart prebuilt standalone release under /var/www/chatbot.
set -euo pipefail

APP_DIR="/var/www/chatbot"

configure_nginx() {
  if [[ ! -d /etc/nginx/conf.d ]]; then
    return 0
  fi

  cp "$APP_DIR/deploy/nginx.conf" /etc/nginx/conf.d/chatbot.conf
  nginx -t
  systemctl enable nginx
  systemctl restart nginx
}

ensure_pm2() {
  npm config set registry https://registry.npmjs.org/
  if ! command -v pm2 >/dev/null 2>&1; then
    npm install -g pm2
  fi
  pm2 startup systemd -u root --hp /root >/dev/null 2>&1 || true
}

if [[ ! -f "$APP_DIR/server.js" ]]; then
  echo "ERROR: $APP_DIR/server.js not found. Run deploy workflow first."
  exit 1
fi

ensure_pm2

echo "==> Reload PM2"
if pm2 describe chatbot >/dev/null 2>&1; then
  pm2 reload "$APP_DIR/deploy/ecosystem.config.cjs" --update-env
else
  pm2 start "$APP_DIR/deploy/ecosystem.config.cjs"
fi

pm2 save
configure_nginx

echo "==> Deploy finished"
