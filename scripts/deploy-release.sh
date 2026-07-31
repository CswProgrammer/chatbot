#!/usr/bin/env bash
# Restart prebuilt standalone release under /var/www/chatbot.
set -euo pipefail

APP_DIR="/var/www/chatbot"

configure_nginx() {
  local conf_src="$APP_DIR/deploy/nginx.conf"

  if [[ -d /www/server/panel/vhost/nginx ]]; then
    cp "$conf_src" /www/server/panel/vhost/nginx/chatbot.conf
    configure_port80_ai
    nginx -t
    /etc/init.d/nginx reload 2>/dev/null || systemctl reload nginx
  elif [[ -d /etc/nginx/conf.d ]]; then
    cp "$conf_src" /etc/nginx/conf.d/chatbot.conf
    nginx -t
    systemctl enable nginx
    systemctl restart nginx
  fi

  firewall-cmd --permanent --add-port=8080/tcp 2>/dev/null || true
  firewall-cmd --reload 2>/dev/null || true
}

configure_port80_ai() {
  local site_conf="/www/server/panel/vhost/nginx/82.156.149.118.conf"
  local marker="# chatbot-ai-proxy"

  if [[ ! -f "$site_conf" ]] || grep -q "$marker" "$site_conf"; then
    return
  fi

  sed -i "/^}$/i\\
\\
    ${marker}\\
    location ^~ /ai {\\
        proxy_pass http://127.0.0.1:3001;\\
        proxy_http_version 1.1;\\
        proxy_set_header Host \$host;\\
        proxy_set_header X-Real-IP \$remote_addr;\\
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\\
        proxy_set_header X-Forwarded-Proto \$scheme;\\
        proxy_set_header Upgrade \$http_upgrade;\\
        proxy_set_header Connection \"upgrade\";\\
        proxy_read_timeout 300s;\\
        proxy_send_timeout 300s;\\
    }" "$site_conf"
}

ensure_postgres() {
  if ! docker ps --format '{{.Names}}' | grep -qx chatbot-postgres; then
    if docker ps -a --format '{{.Names}}' | grep -qx chatbot-postgres; then
      docker start chatbot-postgres
    else
      docker run -d \
        --name chatbot-postgres \
        --restart unless-stopped \
        -e POSTGRES_USER=chatbot \
        -e POSTGRES_PASSWORD=chatbot_pg_2026_xK9m \
        -e POSTGRES_DB=chatbot \
        -p 127.0.0.1:5432:5432 \
        -v chatbot-pgdata:/var/lib/postgresql/data \
        postgres:16-alpine
    fi
  fi
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

ensure_postgres

echo "==> Reload PM2"
if pm2 describe chatbot >/dev/null 2>&1; then
  pm2 reload "$APP_DIR/deploy/ecosystem.config.cjs" --update-env
else
  pm2 start "$APP_DIR/deploy/ecosystem.config.cjs"
fi

pm2 save
configure_nginx

echo "==> Deploy finished"
