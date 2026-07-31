#!/usr/bin/env bash
# Idempotent production deploy for Tencent Lighthouse (OpenCloudOS).
set -euo pipefail

APP_DIR="/var/www/chatbot"
BRANCH="${DEPLOY_BRANCH:-main}"
REPO_URL="${REPO_URL:-https://github.com/CswProgrammer/chatbot.git}"

export HUSKY=0
export NODE_ENV=production

ensure_node_toolchain() {
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
}

write_env_file() {
  if [[ -z "${AUTH_SECRET:-}" || -z "${DEEPSEEK_API_KEY:-}" || -z "${POSTGRES_URL:-}" ]]; then
    echo "ERROR: Missing AUTH_SECRET, DEEPSEEK_API_KEY, or POSTGRES_URL in deploy environment."
    exit 1
  fi

  cat >"$APP_DIR/.env.local" <<EOF
AUTH_SECRET=${AUTH_SECRET}
DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY}
POSTGRES_URL=${POSTGRES_URL}
AUTH_URL=${AUTH_URL:-http://82.156.149.118}
NODE_ENV=production
PORT=3000
EOF
  chmod 600 "$APP_DIR/.env.local"
}

configure_nginx() {
  if [[ ! -d /etc/nginx/conf.d ]]; then
    return 0
  fi

  cp "$APP_DIR/deploy/nginx.conf" /etc/nginx/conf.d/chatbot.conf
  nginx -t
  systemctl enable nginx
  systemctl restart nginx
}

ensure_node_toolchain
mkdir -p "$APP_DIR"

if [[ "${SKIP_GIT:-}" != "1" && ! -d "$APP_DIR/.git" ]]; then
  git clone "$REPO_URL" "$APP_DIR"
fi

cd "$APP_DIR"

write_env_file

if [[ "${SKIP_GIT:-}" != "1" ]]; then
  echo "==> Fetch latest ${BRANCH}"
  git fetch origin "$BRANCH"
  git reset --hard "origin/${BRANCH}"
fi

echo "==> Install dependencies"
pnpm install --frozen-lockfile --ignore-scripts

echo "==> Build application"
pnpm run build

echo "==> Reload PM2"
if pm2 describe chatbot >/dev/null 2>&1; then
  pm2 reload deploy/ecosystem.config.cjs --update-env
else
  pm2 start deploy/ecosystem.config.cjs
fi

pm2 save
configure_nginx

echo "==> Deploy finished"
