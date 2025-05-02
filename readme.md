# N8N Blue/Green Deployment Template

This repository provides a Docker-based deployment setup for running [N8N](https://n8n.io) in **blue/green mode**, with **zero-downtime updates** using **Caddy** as a reverse proxy.

_*Note The docker structure is strongly inspired (almost as is) as the one in [N8N's repo example](https://github.com/n8n-io/n8n-hosting/tree/main/docker-compose/withPostgresAndWorker)_


## 📦 What's Included

- `docker-compose.base.yml`: defines shared services (Postgres, Redis)
- `docker-compose.blue.yml`: blue stack (main + worker)
- `docker-compose.green.yml`: green stack (main + worker)
- `scripts/switch_stack.sh`: toggles between blue and green
- `scripts/gracefully_update.sh`: checks for new N8N image and switches if needed
- `caddy/Caddyfile`: template to routes traffic to the active stack
- `.n8n_active_stack.json`: tracks which stack is active
- `.env.example`: template file for shared environment variables
- `install.sh`: automated caddy setup script

---

## 🚀 Getting Started

### 1. Clone and configure

```bash
git clone https://github.com/dynamicNerdsSolutions/n8n-blue-green-docker-compose
cd n8n-blue-green-docker-compose
cp .env.example .env
```

Edit `.env` and set your values. Required variables:
- `POSTGRES_USER`: Database root user
- `POSTGRES_PASSWORD`: Database root password
- `POSTGRES_DB`: Database name
- `POSTGRES_NON_ROOT_USER`: Application database user
- `POSTGRES_NON_ROOT_PASSWORD`: Application database password
- `ENCRYPTION_KEY`: n8n encryption key


### 2. Install Caddy and Run the Setup Script
#### Caddy install
Follow the [instructions to install Caddy](https://caddyserver.com/docs/install)

#### Setup for the project
Better to do it on a clean server, otherwise, take some time to read what the script does.

Not compatible with nginx if it is installed and running

```bash
sudo ./install.sh
```

Follow the prompts to enter your domain name. The script will:
- Create necessary Caddy directories
- Configure your domain
- Set up the reverse proxy
- Enable and start Caddy

Make sure:
- DNS is configured for your domain
- Ports 80/443 are open
- You have sudo privileges

---

## 💡 Deployment Workflow

### ✅ Initial deployment

```bash
# Create initial state file
echo '{"active_stack": "blue", "last_switch": null}' > .n8n_active_stack.json

# Start the blue stack
docker compose -f docker-compose.blue.yml up -d
```

### ✅ Switch stack

```bash
./scripts/switch_stack.sh
```

This toggles between blue and green, updates the Caddy reverse proxy, and stops the old main container. The script:
- Starts the target stack
- Waits for health check
- Updates Caddy configuration
- Updates state file
- Stops the old stack

### ✅ Check for updates + switch (automated)

```bash
./scripts/gracefully_update.sh
```

- Pulls latest N8N image
- Compares image digest
- Switches stack only if the image is new

### ✅ Set up automatic daily updates

To automatically check for updates every day at midnight, add this to your crontab:

```bash
# Edit crontab
crontab -e

# Add this line (adjust the path to match your installation)
0 0 * * * cd /path/to/n8n-blue-green-docker-compose && ./scripts/gracefully_update.sh >> /var/log/n8n-updates.log 2>&1
```

This will:
- Run the update check at midnight every day
- Log the output to `/var/log/n8n-updates.log`
- Only switch stacks if a new version is available

---

## ⚠️ Important Notes

- **Only one `main` container should be active at a time**. Having two can cause:
  - duplicate scheduled executions
  - webhook registration conflicts

- **Workers can run concurrently** during the transition (safe).

- **Make sure Redis uses a persistent volume** if you want to preserve queue state across restarts.

- **Healthcheck before switching** ensures no downtime. The script waits until `/healthz` responds OK.

- The `.n8n_active_stack.json` file tracks which stack is currently active. Don't modify it manually.

---

## 🪄 Cleanup

To stop everything:

```bash
docker compose -f docker-compose.base.yml -f docker-compose.blue.yml down
docker compose -f docker-compose.base.yml -f docker-compose.green.yml down
```

---

## 🧪 Tested With

- Docker Compose v2
- Caddy v2
- N8N 1.9+
- Ubuntu 22.04 LTS

---

Happy automating! 🤖
