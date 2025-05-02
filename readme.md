# N8N Blue/Green Deployment Template

This repository provides a Docker-based deployment setup for running [N8N](https://n8n.io) in **blue/green mode**, with **zero-downtime updates** using **Caddy** as a reverse proxy.

## 📦 What's Included

- `docker-compose.base.yml`: defines shared services (Postgres, Redis)
- `docker-compose.blue.yml`: blue stack (main + worker)
- `docker-compose.green.yml`: green stack (main + worker)
- `scripts/switch_stack.sh`: toggles between blue and green
- `scripts/gracefully_update.sh`: checks for new N8N image and switches if needed
- `caddy/Caddyfile`: routes traffic to the active stack
- `.n8n_active_stack.json`: tracks which stack is active
- `.env`: shared environment variables

---

## 🚀 Getting Started

### 1. Clone and configure

```bash
git clone https://your-repo.git
cd n8n-blue-green-docker-compose
cp .env.example .env
```

Edit `.env` and set your values.

### 2. Setup Caddy

Install [Caddy](https://caddyserver.com/docs/install) **directly on the server (not via Docker)**.

Edit `caddy/caddy.service` to use your actual domain and start the service:

```bash
sudo cp caddy/Caddyfile /etc/caddy/Caddyfile
sudo systemctl enable --now caddy
```

### Caddyfile example

```caddy
automation.MY_DOMAIN.TLD {
  reverse_proxy n8n-blue-main:5678
}
```

Replace `MY_DOMAIN.TLD` with your actual domain. Make sure DNS is set and ports 80/443 are open.

---

## 💡 Deployment Workflow

### ✅ Initial deployment

```bash
docker-compose -f docker-compose.base.yml -f docker-compose.blue.yml up -d
```

### ✅ Switch stack

```bash
./scripts/switch_stack.sh
```

This toggles between blue and green, updates the Caddy reverse proxy, and stops the old main container. Usually called from gracefully_update.sh

### ✅ Check for updates + switch (automated)

```bash
./scripts/gracefully_update.sh
```

- Pulls latest N8N image
- Compares image digest
- Switches stack only if the image is new

---

## ⚠️ Gotchas & Notes

- **Caddy vs NGINX**: If NGINX is running, it will block ports 80/443. You must stop or uninstall NGINX before running Caddy if you want to use this repo right out of the box.
  
  ```bash
  sudo systemctl stop nginx
  sudo systemctl disable nginx
  ```

- **Only one `main` container should be active at a time**. Having two can cause:
  - duplicate scheduled executions
  - webhook registration conflicts

- **Workers can run concurrently** during the transition (safe).

- **Make sure Redis uses a persistent volume** if you want to preserve queue state across restarts.

- **Healthcheck before switching** ensures no downtime. The script waits until `/healthz` responds OK.

- **Cron triggers are not automatically analyzed** yet — you can extend the script to delay switching if a cron task is about to fire.

- You must maintain the `.n8n_active_stack.json` file — it tracks which stack is currently active.


---

## 🪄 Cleanup

To stop everything:

```bash
docker-compose -f docker-compose.base.yml -f docker-compose.blue.yml down
docker-compose -f docker-compose.base.yml -f docker-compose.green.yml down
```

---

## 🧪 Tested With

- Docker Compose v2
- Caddy v2
- N8N 1.9
- Ubuntu 22.04 LTS

---

## 🛠 Future Improvements

- Auto-check for cron tasks before switching
- Add webhook retry/buffer proxy (if required)

---

Happy automating! 🤖
