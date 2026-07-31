# Production deployment (GitHub Actions)

Deploys to Tencent Lighthouse on every push to `main`.

## GitHub Secrets

Configure these in **Settings → Secrets and variables → Actions**:

| Secret | Description |
| --- | --- |
| `DEPLOY_HOST` | Server public IP, e.g. `82.156.149.118` |
| `DEPLOY_PORT` | SSH port, e.g. `10002` |
| `DEPLOY_USER` | SSH user, e.g. `root` |
| `DEPLOY_PASSWORD` | SSH password (or use `DEPLOY_SSH_KEY` instead) |
| `DEPLOY_SSH_KEY` | Optional private key for passwordless deploy |
| `AUTH_SECRET` | NextAuth secret |
| `DEEPSEEK_API_KEY` | DeepSeek API key |
| `POSTGRES_URL` | Postgres connection string |
| `AUTH_URL` | Public app URL, e.g. `http://82.156.149.118:8080` |

## Server layout

- App directory: `/var/www/chatbot`
- Process manager: PM2 (`chatbot`)
- Reverse proxy: nginx → `127.0.0.1:3000`

## Manual bootstrap (optional)

```bash
export DEPLOY_PUBKEY="your-github-actions-public-key"
bash scripts/server-bootstrap.sh
```

Normal deploys are handled by `.github/workflows/deploy.yml`.
