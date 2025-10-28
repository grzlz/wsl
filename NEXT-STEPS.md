# Next Steps - Complete Implementation Guide

This document outlines the exact steps to transform your current setup into a production-ready architecture with Caddy reverse proxy.

---

## Table of Contents

1. [Current State Assessment](#current-state-assessment)
2. [Step 1: Prepare Your Project Structure](#step-1-prepare-your-project-structure)
3. [Step 2: Create Caddy Configuration](#step-2-create-caddy-configuration)
4. [Step 3: Update Docker Compose](#step-3-update-docker-compose)
5. [Step 4: Deploy with Caddy](#step-4-deploy-with-caddy)
6. [Step 5: Verify Everything Works](#step-5-verify-everything-works)
7. [Step 6: Add Second SvelteKit App (Optional)](#step-6-add-second-sveltekit-app-optional)
8. [Step 7: Set Up Monitoring Stack (Optional)](#step-7-set-up-monitoring-stack-optional)
9. [Step 8: Production Hardening](#step-8-production-hardening)
10. [Step 9: Domain & HTTPS Setup (Optional)](#step-9-domain--https-setup-optional)
11. [Common Issues & Troubleshooting](#common-issues--troubleshooting)
12. [Quick Reference Commands](#quick-reference-commands)

---

## Current State Assessment

### What You Have Now
- ✅ WSL2 Ubuntu installed
- ✅ Docker Engine installed and running
- ✅ Docker Compose installed
- ✅ Basic understanding of the architecture
- ✅ (Presumably) A SvelteKit app or ready to create one

### What We'll Build
- 🎯 Caddy reverse proxy handling all HTTP/HTTPS traffic
- 🎯 One or more SvelteKit apps running behind Caddy
- 🎯 Professional URL routing (path-based or domain-based)
- 🎯 (Optional) Complete monitoring stack
- 🎯 Production-ready configuration

---

## Step 1: Prepare Your Project Structure

### 1.1 Navigate to WSL2

Open Windows Terminal and enter WSL:

```bash
wsl
```

### 1.2 Create Project Directory Structure

```bash
# Create main project directory
mkdir -p ~/projects/sveltekit-apps
cd ~/projects/sveltekit-apps

# Create Caddy configuration directories
mkdir -p caddy/config
mkdir -p caddy/data

# Create monitoring directories (optional, for later)
mkdir -p monitoring/prometheus
mkdir -p monitoring/grafana/provisioning/datasources
mkdir -p monitoring/grafana/provisioning/dashboards
mkdir -p monitoring/loki
mkdir -p monitoring/promtail
```

### 1.3 Verify Directory Structure

```bash
tree -L 2 ~/projects/sveltekit-apps
```

Expected output:
```
~/projects/sveltekit-apps
├── caddy
│   ├── config
│   └── data
└── monitoring
    ├── grafana
    ├── loki
    ├── prometheus
    └── promtail
```

---

## Step 2: Create Caddy Configuration

### 2.1 Create Caddyfile

This is Caddy's main configuration file:

```bash
cd ~/projects/sveltekit-apps
nano caddy/config/Caddyfile
```

### 2.2 Add Basic Caddyfile Configuration

**Option A: Single App (Simple)**

If you have just one app:

```caddyfile
# Global options
{
    # Disable admin API (security)
    admin off

    # Email for Let's Encrypt (change this!)
    email your-email@example.com
}

# Local development - no HTTPS
localhost:80 {
    # Reverse proxy to app1
    reverse_proxy app1:3000 {
        # Preserve client information
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
    }

    # Enable logging
    log {
        output stdout
        format console
    }
}
```

**Option B: Multiple Apps - Path-Based Routing**

If you plan to run multiple apps with different URL paths:

```caddyfile
# Global options
{
    admin off
    email your-email@example.com
}

localhost:80 {
    # Route to app1 at /app1
    route /app1/* {
        uri strip_prefix /app1
        reverse_proxy app1:3000 {
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
        }
    }

    # Route to app2 at /app2
    route /app2/* {
        uri strip_prefix /app2
        reverse_proxy app2:3000 {
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
        }
    }

    # Default route (optional - redirect to app1)
    route /* {
        reverse_proxy app1:3000 {
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
        }
    }

    log {
        output stdout
        format console
    }
}
```

**Option C: Multiple Apps - Subdomain Routing (For Production)**

If you have a domain name and want subdomain-based routing:

```caddyfile
# Global options
{
    admin off
    email your-email@example.com
}

# App 1
app1.yourdomain.com {
    reverse_proxy app1:3000 {
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
    }

    log {
        output stdout
        format console
    }
}

# App 2
app2.yourdomain.com {
    reverse_proxy app2:3000 {
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
    }

    log {
        output stdout
        format console
    }
}

# Main site
yourdomain.com {
    reverse_proxy app1:3000

    log {
        output stdout
        format console
    }
}
```

### 2.3 Save the File

- Press `Ctrl + X`
- Press `Y` to confirm
- Press `Enter` to save

### 2.4 Verify Caddyfile Syntax

```bash
# We'll verify syntax after starting Caddy
# For now, just check the file exists
cat caddy/config/Caddyfile
```

---

## Step 3: Update Docker Compose

### 3.1 Check for Existing docker-compose.yml

```bash
cd ~/projects/sveltekit-apps
ls -la
```

### 3.2 Create/Update docker-compose.yml

**If you DON'T have a docker-compose.yml yet:**

```bash
nano docker-compose.yml
```

Add this complete configuration:

```yaml
version: '3.8'

# Services (containers)
services:

  # Caddy Reverse Proxy - The Gateway
  caddy:
    image: caddy:2-alpine
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"       # HTTP
      - "443:443"     # HTTPS
      - "443:443/udp" # HTTP/3 (QUIC)
    volumes:
      # Mount Caddyfile (read-only)
      - ./caddy/config/Caddyfile:/etc/caddy/Caddyfile:ro
      # Persistent storage for certificates
      - ./caddy/data:/data
      - ./caddy/config:/config
    networks:
      - web
    depends_on:
      - app1
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:80/"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s

  # SvelteKit App 1 - Your Application
  app1:
    build:
      context: ./app1
      dockerfile: Dockerfile
    container_name: app1
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - PORT=3000
      - HOST=0.0.0.0
    # NO PORTS EXPOSED - Internal only
    networks:
      - web
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 40s

# Networks
networks:
  web:
    driver: bridge
    name: sveltekit_web

# Volumes for data persistence
volumes:
  caddy_data:
    driver: local
  caddy_config:
    driver: local
```

**If you ALREADY have a docker-compose.yml:**

You need to:
1. Remove the `ports:` section from your app1 service
2. Add the entire `caddy:` service block above
3. Ensure the `networks:` and `volumes:` sections are present

### 3.3 Save and Exit

- Press `Ctrl + X`
- Press `Y`
- Press `Enter`

---

## Step 4: Deploy with Caddy

### 4.1 Check if You Have a SvelteKit App

```bash
ls -la ~/projects/sveltekit-apps/
```

**If you DON'T have an app1 folder, create one now:**

```bash
cd ~/projects/sveltekit-apps

# Check if Node.js is installed
node --version

# If not installed, install Node.js 20 LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Create SvelteKit app
npm create svelte@latest app1
```

**When prompted:**
- Template: Choose "SvelteKit demo app" (or "Skeleton project")
- TypeScript: Yes (recommended)
- ESLint: Yes
- Prettier: Yes
- Playwright: Optional
- Vitest: Optional

```bash
# Install dependencies
cd app1
npm install

# Install Node adapter
npm install -D @sveltejs/adapter-node
```

**Configure svelte.config.js:**

```bash
nano svelte.config.js
```

Make sure it looks like this:

```javascript
import adapter from '@sveltejs/adapter-node';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
  preprocess: vitePreprocess(),

  kit: {
    adapter: adapter({
      out: 'build',
      precompress: true,
      envPrefix: ''
    })
  }
};

export default config;
```

### 4.2 Create Dockerfile for app1

```bash
cd ~/projects/sveltekit-apps/app1
nano Dockerfile
```

Add this production-ready Dockerfile:

```dockerfile
# syntax=docker/dockerfile:1

# ============================================
# Stage 1: Build
# ============================================
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies (use ci for reproducible builds)
RUN npm ci

# Copy all source code
COPY . .

# Build the SvelteKit app
RUN npm run build

# Remove dev dependencies
RUN npm prune --production

# ============================================
# Stage 2: Production
# ============================================
FROM node:20-alpine

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Set working directory
WORKDIR /app

# Copy built application from builder
COPY --from=builder --chown=nodejs:nodejs /app/build ./build
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Environment variables
ENV NODE_ENV=production \
    PORT=3000 \
    HOST=0.0.0.0

# Use dumb-init to handle signals
ENTRYPOINT ["dumb-init", "--"]

# Start the application
CMD ["node", "build"]
```

### 4.3 Create .dockerignore

```bash
nano .dockerignore
```

Add:

```
node_modules
.git
.svelte-kit
build
.env
.env.*
!.env.example
npm-debug.log
.DS_Store
.vscode
.idea
*.md
!README.md
.github
Dockerfile
.dockerignore
dist
.turbo
coverage
.next
.nuxt
```

### 4.4 Start Docker Service (if not running)

```bash
# Check if Docker is running
sudo service docker status

# If not running, start it
sudo service docker start
```

### 4.5 Build and Deploy Everything

```bash
cd ~/projects/sveltekit-apps

# Build all images
docker compose build

# Start all services in detached mode
docker compose up -d
```

**Expected output:**
```
[+] Building ...
[+] Running 2/2
 ✔ Container app1   Started
 ✔ Container caddy  Started
```

---

## Step 5: Verify Everything Works

### 5.1 Check Container Status

```bash
docker compose ps
```

Expected output:
```
NAME      IMAGE              STATUS         PORTS
caddy     caddy:2-alpine     Up (healthy)   0.0.0.0:80->80/tcp, ...
app1      app1               Up (healthy)
```

Both should show "Up" status.

### 5.2 Check Logs

```bash
# View all logs
docker compose logs

# View Caddy logs specifically
docker compose logs caddy

# View app1 logs specifically
docker compose logs app1

# Follow logs in real-time
docker compose logs -f
```

**Good signs to look for:**
- Caddy: `{"level":"info","msg":"serving initial configuration"}`
- app1: `Listening on 0.0.0.0:3000`

### 5.3 Test From Windows Browser

Open your Windows web browser and go to:

```
http://localhost
```

You should see your SvelteKit app!

**If you chose path-based routing:**
```
http://localhost/app1
```

### 5.4 Test Caddy Routing

```bash
# Test from WSL
curl http://localhost

# Test with verbose output
curl -v http://localhost

# Check Caddy is responding
curl -I http://localhost
```

### 5.5 Verify Internal Networking

```bash
# Enter Caddy container
docker exec -it caddy sh

# From inside Caddy, test connection to app1
wget -O- http://app1:3000

# Exit container
exit
```

If you see HTML output, internal networking is working!

---

## Step 6: Add Second SvelteKit App (Optional)

### 6.1 Create Second App

```bash
cd ~/projects/sveltekit-apps
npm create svelte@latest app2
cd app2
npm install
npm install -D @sveltejs/adapter-node
```

### 6.2 Configure app2

Update `svelte.config.js` (same as app1):

```bash
nano svelte.config.js
```

### 6.3 Copy Dockerfile and .dockerignore

```bash
cp ../app1/Dockerfile ./
cp ../app1/.dockerignore ./
```

### 6.4 Update Caddyfile

```bash
nano ~/projects/sveltekit-apps/caddy/config/Caddyfile
```

Add routing for app2 (if using path-based routing):

```caddyfile
localhost:80 {
    route /app1/* {
        uri strip_prefix /app1
        reverse_proxy app1:3000
    }

    route /app2/* {
        uri strip_prefix /app2
        reverse_proxy app2:3000
    }

    # Default to app1
    route /* {
        reverse_proxy app1:3000
    }

    log {
        output stdout
        format console
    }
}
```

### 6.5 Update docker-compose.yml

```bash
nano ~/projects/sveltekit-apps/docker-compose.yml
```

Add app2 service (copy app1 block and modify):

```yaml
  app2:
    build:
      context: ./app2
      dockerfile: Dockerfile
    container_name: app2
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - PORT=3000
      - HOST=0.0.0.0
    networks:
      - web
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 40s
```

Also update Caddy's `depends_on`:

```yaml
  caddy:
    # ... other config ...
    depends_on:
      - app1
      - app2
```

### 6.6 Deploy Second App

```bash
cd ~/projects/sveltekit-apps

# Rebuild with new app
docker compose up -d --build
```

### 6.7 Test Both Apps

```
http://localhost/app1
http://localhost/app2
```

---

## Step 7: Set Up Monitoring Stack (Optional)

This adds Prometheus, Grafana, Loki for monitoring your apps.

### 7.1 Create Prometheus Configuration

```bash
cd ~/projects/sveltekit-apps
nano monitoring/prometheus/prometheus.yml
```

Add:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    monitor: 'sveltekit-server'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
```

### 7.2 Create Loki Configuration

```bash
nano monitoring/loki/loki-config.yml
```

Add:

```yaml
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

limits_config:
  retention_period: 168h

compactor:
  working_directory: /loki/compactor
  shared_store: filesystem
  retention_enabled: true
  retention_delete_delay: 2h
```

### 7.3 Create Promtail Configuration

```bash
nano monitoring/promtail/promtail-config.yml
```

Add:

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: docker
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 5s
    relabel_configs:
      - source_labels: ['__meta_docker_container_name']
        regex: '/(.*)'
        target_label: 'container'
      - source_labels: ['__meta_docker_container_log_stream']
        target_label: 'logstream'
      - source_labels: ['__meta_docker_container_label_com_docker_compose_service']
        target_label: 'service'
```

### 7.4 Create Grafana Datasource Configuration

```bash
nano monitoring/grafana/provisioning/datasources/datasources.yml
```

Add:

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true

  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    editable: true
```

### 7.5 Add Monitoring Services to docker-compose.yml

```bash
nano docker-compose.yml
```

Add these services at the end of the `services:` section:

```yaml
  # Prometheus - Metrics Collection
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    volumes:
      - ./monitoring/prometheus:/etc/prometheus
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
    ports:
      - "9090:9090"
    networks:
      - monitoring

  # Grafana - Visualization
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning
    networks:
      - monitoring
    depends_on:
      - prometheus
      - loki

  # Loki - Log Aggregation
  loki:
    image: grafana/loki:latest
    container_name: loki
    restart: unless-stopped
    ports:
      - "3100:3100"
    volumes:
      - ./monitoring/loki:/etc/loki
      - loki_data:/loki
    command: -config.file=/etc/loki/loki-config.yml
    networks:
      - monitoring

  # Promtail - Log Shipping
  promtail:
    image: grafana/promtail:latest
    container_name: promtail
    restart: unless-stopped
    volumes:
      - ./monitoring/promtail:/etc/promtail
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
    command: -config.file=/etc/promtail/promtail-config.yml
    networks:
      - monitoring
    depends_on:
      - loki

  # cAdvisor - Container Metrics
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    restart: unless-stopped
    privileged: true
    devices:
      - /dev/kmsg:/dev/kmsg
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    ports:
      - "8080:8080"
    networks:
      - monitoring

  # Node Exporter - System Metrics
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    ports:
      - "9100:9100"
    networks:
      - monitoring
```

Add the monitoring network and volumes:

```yaml
networks:
  web:
    driver: bridge
    name: sveltekit_web
  monitoring:
    driver: bridge
    name: sveltekit_monitoring

volumes:
  caddy_data:
  caddy_config:
  prometheus_data:
  grafana_data:
  loki_data:
```

### 7.6 Deploy Monitoring Stack

```bash
docker compose up -d
```

### 7.7 Access Monitoring Tools

**Grafana:** `http://localhost:3001`
- Username: `admin`
- Password: `admin` (change on first login)

**Prometheus:** `http://localhost:9090`

**cAdvisor:** `http://localhost:8080`

### 7.8 Import Dashboards in Grafana

1. Open Grafana
2. Click "+" → "Import Dashboard"
3. Enter dashboard ID: `193` (Docker monitoring)
4. Click "Load"
5. Select "Prometheus" as data source
6. Click "Import"

---

## Step 8: Production Hardening

### 8.1 Set Resource Limits

Update docker-compose.yml to add resource limits:

```yaml
  app1:
    # ... existing config ...
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

### 8.2 Add Health Endpoints

Create health check in your SvelteKit app:

```bash
cd ~/projects/sveltekit-apps/app1
mkdir -p src/routes/health
nano src/routes/health/+server.js
```

Add:

```javascript
/** @type {import('./$types').RequestHandler} */
export function GET() {
  return new Response('OK', {
    status: 200,
    headers: {
      'Content-Type': 'text/plain'
    }
  });
}
```

### 8.3 Use Environment Variables

Create `.env` file:

```bash
cd ~/projects/sveltekit-apps
nano .env
```

Add:

```env
# Node Environment
NODE_ENV=production

# Database (example)
DATABASE_URL=postgresql://user:password@localhost:5432/mydb

# API Keys (example)
API_KEY=your-secret-key-here

# Session Secret
SESSION_SECRET=change-this-to-random-string
```

**IMPORTANT:** Add to `.gitignore`:

```bash
echo ".env" >> .gitignore
```

Update docker-compose.yml:

```yaml
  app1:
    # ... existing config ...
    env_file:
      - .env
```

### 8.4 Enable Automatic Updates with Watchtower

Add to docker-compose.yml:

```yaml
  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_POLL_INTERVAL=86400
      - WATCHTOWER_LABEL_ENABLE=true
    networks:
      - web
```

### 8.5 Set Up Automated Backups

Create backup script:

```bash
nano ~/backup-docker.sh
```

Add:

```bash
#!/bin/bash

# Configuration
BACKUP_DIR="/mnt/c/Backups/docker"
DATE=$(date +%Y%m%d_%H%M%S)
COMPOSE_DIR="$HOME/projects/sveltekit-apps"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup configurations
tar czf "$BACKUP_DIR/configs_$DATE.tar.gz" \
  "$COMPOSE_DIR/caddy" \
  "$COMPOSE_DIR/monitoring" \
  "$COMPOSE_DIR/docker-compose.yml" \
  "$COMPOSE_DIR/.env"

# Backup Docker volumes
docker run --rm \
  -v sveltekit_caddy_data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf "/backup/caddy_data_$DATE.tar.gz" /data

# Keep only last 7 days
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
```

Make executable:

```bash
chmod +x ~/backup-docker.sh
```

Test it:

```bash
~/backup-docker.sh
```

---

## Step 9: Domain & HTTPS Setup (Optional)

If you have a domain and want production HTTPS:

### 9.1 Prerequisites

- ✅ Own a domain name
- ✅ Domain DNS A record points to your public IP
- ✅ Router port forwarding: 80 → your PC's local IP
- ✅ Router port forwarding: 443 → your PC's local IP

### 9.2 Update Caddyfile for Production

```bash
nano ~/projects/sveltekit-apps/caddy/config/Caddyfile
```

Replace with:

```caddyfile
{
    admin off
    email your-email@example.com
}

# Main app
yourdomain.com {
    reverse_proxy app1:3000 {
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
    }

    log {
        output stdout
        format console
    }
}

# App 2 on subdomain
app2.yourdomain.com {
    reverse_proxy app2:3000 {
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
    }

    log {
        output stdout
        format console
    }
}

# Redirect www to non-www
www.yourdomain.com {
    redir https://yourdomain.com{uri} permanent
}
```

### 9.3 Restart Caddy

```bash
docker compose restart caddy
```

### 9.4 Verify HTTPS

```bash
# Check certificates
docker exec caddy ls -la /data/caddy/certificates

# Test from outside
curl -I https://yourdomain.com
```

Caddy will automatically:
- Obtain SSL certificate from Let's Encrypt
- Redirect HTTP to HTTPS
- Renew certificates before expiration

---

## Common Issues & Troubleshooting

### Issue 1: Container Won't Start

```bash
# Check logs
docker compose logs app1

# Check if port is already in use
sudo netstat -tulpn | grep :80

# Rebuild from scratch
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Issue 2: Can't Access from Windows

```bash
# Test from WSL
curl http://localhost

# If works in WSL but not Windows, restart WSL
# (From Windows PowerShell)
wsl --shutdown
wsl
```

### Issue 3: Caddy Shows "No Such Host"

```bash
# Verify container can reach app
docker exec caddy ping -c 3 app1

# Check network
docker network inspect sveltekit_web

# Verify app is running
docker compose ps
```

### Issue 4: Build Fails

```bash
# Clean Docker system
docker system prune -a
docker volume prune

# Check disk space
df -h

# Rebuild
docker compose build --no-cache
```

### Issue 5: 502 Bad Gateway

This means Caddy can't reach the app:

```bash
# Check if app is actually listening
docker exec app1 wget -O- http://localhost:3000

# Check app logs
docker compose logs app1

# Verify health check
docker inspect app1 | grep -A 10 Health
```

---

## Quick Reference Commands

### Docker Compose

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# View logs
docker compose logs -f

# Restart specific service
docker compose restart caddy

# Rebuild and restart
docker compose up -d --build

# Check status
docker compose ps

# Scale service (run multiple instances)
docker compose up -d --scale app1=3
```

### Docker

```bash
# List running containers
docker ps

# List all containers
docker ps -a

# View logs
docker logs <container-name>

# Enter container shell
docker exec -it <container-name> sh

# View resource usage
docker stats

# Clean up
docker system prune
docker volume prune
```

### Useful One-Liners

```bash
# Stop and remove everything
docker compose down -v

# Rebuild everything from scratch
docker compose down && docker compose build --no-cache && docker compose up -d

# View Caddy config
docker exec caddy cat /etc/caddy/Caddyfile

# Reload Caddy config without restart
docker exec caddy caddy reload --config /etc/caddy/Caddyfile

# Check Caddy syntax
docker exec caddy caddy validate --config /etc/caddy/Caddyfile
```

---

## Summary Checklist

Use this checklist to track your progress:

- [ ] Created project directory structure
- [ ] Created Caddyfile configuration
- [ ] Created/updated docker-compose.yml
- [ ] Created at least one SvelteKit app
- [ ] Created Dockerfile for app
- [ ] Built Docker images
- [ ] Started all containers
- [ ] Verified app accessible at `http://localhost`
- [ ] Checked container logs for errors
- [ ] (Optional) Added second app
- [ ] (Optional) Set up monitoring stack
- [ ] (Optional) Added health checks
- [ ] (Optional) Configured environment variables
- [ ] (Optional) Set up automated backups
- [ ] (Optional) Configured custom domain with HTTPS

---

## What's Next?

Once you've completed these steps, you'll have:

✅ Production-ready SvelteKit hosting infrastructure
✅ Automatic HTTPS with Caddy
✅ Container orchestration with Docker Compose
✅ (Optional) Complete monitoring and logging
✅ Scalable architecture

**Future Enhancements:**
- Add database (PostgreSQL, MongoDB)
- Add caching layer (Redis)
- Implement CI/CD pipeline
- Add email alerts
- Set up automated deployments
- Implement horizontal scaling

---

**Need Help?**

1. Check logs: `docker compose logs -f`
2. Review the GUIDE.md for detailed explanations
3. Check architecture-diagrams.md for visual references
4. Search error messages online
5. Verify configurations match examples

**Good luck! 🚀**
