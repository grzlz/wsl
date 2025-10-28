# Complete Guide: Running SvelteKit Apps on Your PC Server with Docker

## Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Understanding the Stack](#understanding-the-stack)
4. [Setting Up Docker on WSL2](#setting-up-docker-on-wsl2)
5. [Creating Your First SvelteKit App](#creating-your-first-sveltekit-app)
6. [Dockerizing SvelteKit Applications](#dockerizing-sveltekit-applications)
7. [Setting Up Caddy Reverse Proxy](#setting-up-caddy-reverse-proxy)
8. [Multi-Container Orchestration with Docker Compose](#multi-container-orchestration-with-docker-compose)
9. [Monitoring and Logging Setup](#monitoring-and-logging-setup)
10. [Managing Multiple SvelteKit Apps](#managing-multiple-sveltekit-apps)
11. [Security Best Practices](#security-best-practices)
12. [Networking and Port Management](#networking-and-port-management)
13. [Data Persistence and Volumes](#data-persistence-and-volumes)
14. [Troubleshooting Common Issues](#troubleshooting-common-issues)
15. [Maintenance and Updates](#maintenance-and-updates)
16. [Advanced Topics](#advanced-topics)

---

## Introduction

This guide will walk you through transforming your Windows PC into a production-ready server for hosting SvelteKit web applications using Docker containers. By the end of this guide, you'll have:

- Docker running on WSL2
- Multiple SvelteKit applications containerized
- Caddy reverse proxy with automatic HTTPS
- Monitoring and logging infrastructure
- Knowledge to maintain and scale your setup

**Important Notes:**
- This guide assumes you're using WSL2 on Windows
- Commands prefixed with `$` should be run in your WSL2 terminal
- Commands prefixed with `>` should be run in Windows PowerShell (if specified)
- Take your time with each section - understanding is more important than speed

---

## Prerequisites

### What You Already Have
- ✅ Windows PC with WSL2 installed
- ✅ Basic command line knowledge

### What You'll Need
- Stable internet connection
- At least 20GB free disk space
- Administrator access to your Windows PC
- (Optional) A domain name if you want public HTTPS access
- (Optional) A static IP address or Dynamic DNS if hosting publicly

### Software Requirements
We'll install these together:
- Docker Engine on WSL2
- Node.js (for SvelteKit development)
- Docker Compose
- Caddy server
- Monitoring tools (Prometheus, Grafana, Loki)

---

## Understanding the Stack

Before diving into installation, let's understand what each component does:

### Docker
Docker is a containerization platform that packages your application and all its dependencies into a single unit called a "container". Think of it like a lightweight virtual machine that starts instantly and uses fewer resources.

**Why Docker?**
- **Isolation**: Each app runs in its own environment
- **Consistency**: Works the same on your PC as it would on any server
- **Easy updates**: Replace containers without affecting others
- **Resource efficiency**: Containers share the OS kernel

### SvelteKit
SvelteKit is a modern web framework for building fast, efficient web applications. It compiles your code to vanilla JavaScript, resulting in smaller bundles and better performance.

**Key Features:**
- Server-side rendering (SSR)
- Static site generation (SSG)
- API routes
- File-based routing

### Caddy
Caddy is a modern web server with automatic HTTPS. Unlike Nginx or Apache, Caddy automatically obtains and renews SSL certificates from Let's Encrypt.

**Why Caddy?**
- Automatic HTTPS setup (zero configuration)
- Simpler configuration than Nginx
- Built-in reverse proxy capabilities
- Automatic HTTP/2 and HTTP/3 support

### WSL2 (Windows Subsystem for Linux)
WSL2 allows you to run a Linux environment directly on Windows without the overhead of a traditional virtual machine. Docker runs much better on Linux than Windows, so we'll use WSL2 as our Docker host.

**Architecture Overview:**
```
┌─────────────────────────────────────────┐
│         Windows Host (Your PC)          │
│  ┌───────────────────────────────────┐  │
│  │           WSL2 (Ubuntu)           │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │       Docker Engine         │  │  │
│  │  │  ┌────────┐    ┌────────┐  │  │  │
│  │  │  │ Caddy  │    │ Logs   │  │  │  │
│  │  │  └────────┘    └────────┘  │  │  │
│  │  │  ┌────────┐    ┌────────┐  │  │  │
│  │  │  │ App 1  │    │ App 2  │  │  │  │
│  │  │  └────────┘    └────────┘  │  │  │
│  │  │  ┌────────┐    ┌────────┐  │  │  │
│  │  │  │Monitor │    │ App N  │  │  │  │
│  │  │  └────────┘    └────────┘  │  │  │
│  │  └─────────────────────────────┘  │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

---

## Setting Up Docker on WSL2

### Step 1: Open Your WSL2 Terminal

1. Open Windows Terminal or PowerShell
2. Type `wsl` and press Enter to enter your WSL2 environment
3. Verify you're in WSL by running:

```bash
$ uname -a
```

You should see output mentioning "Linux" and "WSL2".

### Step 2: Update Your System

Always start with updated packages:

```bash
$ sudo apt update && sudo apt upgrade -y
```

This command:
- `apt update`: Refreshes the package list
- `apt upgrade`: Upgrades installed packages
- `-y`: Automatically answers "yes" to prompts

### Step 3: Install Docker Engine

Docker provides an official installation script:

```bash
$ curl -fsSL https://get.docker.com -o get-docker.sh
$ sudo sh get-docker.sh
```

**What's happening:**
- `curl -fsSL`: Downloads the script securely
- `get.docker.com`: Official Docker installation script
- `sudo sh`: Executes with administrator privileges

### Step 4: Configure Docker for Your User

By default, Docker requires `sudo` for every command. Let's fix that:

```bash
$ sudo usermod -aG docker $USER
```

**Important:** You need to restart your WSL terminal for this to take effect:

```bash
$ exit
```

Then open WSL again with `wsl` command from Windows terminal.

### Step 5: Start Docker Service

WSL2 doesn't automatically start services. You need to start Docker manually:

```bash
$ sudo service docker start
```

To check if Docker is running:

```bash
$ sudo service docker status
```

You should see "Docker is running".

**Pro Tip:** Create a startup script to auto-start Docker. Add this to your `~/.bashrc`:

```bash
$ echo 'if service docker status 2>&1 | grep -q "is not running"; then sudo service docker start; fi' >> ~/.bashrc
```

### Step 6: Verify Docker Installation

Test Docker with the classic hello-world container:

```bash
$ docker run hello-world
```

If you see "Hello from Docker!", you're all set!

### Step 7: Install Docker Compose

Docker Compose allows you to define and run multi-container applications:

```bash
$ sudo apt install docker-compose-plugin -y
```

Verify installation:

```bash
$ docker compose version
```

You should see the version number (e.g., "Docker Compose version v2.x.x").

---

## Creating Your First SvelteKit App

### Step 1: Install Node.js and npm

SvelteKit requires Node.js. We'll use NodeSource to get the latest LTS version:

```bash
$ curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
$ sudo apt install -y nodejs
```

Verify installation:

```bash
$ node --version
$ npm --version
```

You should see Node.js v20.x.x and npm version numbers.

### Step 2: Create a Project Directory

Let's organize our projects:

```bash
$ mkdir -p ~/projects/sveltekit-apps
$ cd ~/projects/sveltekit-apps
```

**Directory Structure:**
```
~/projects/sveltekit-apps/
├── app1/
├── app2/
├── docker-compose.yml
└── caddy/
```

### Step 3: Create Your First SvelteKit App

```bash
$ npm create svelte@latest app1
```

**Interactive Prompts:**
- **Which template?** Choose "SvelteKit demo app" (for learning) or "Skeleton project"
- **Add type checking?** Yes, using TypeScript syntax
- **Add ESLint?** Yes (recommended)
- **Add Prettier?** Yes (recommended)
- **Add Playwright?** Optional (testing framework)
- **Add Vitest?** Optional (unit testing)

Navigate to your app and install dependencies:

```bash
$ cd app1
$ npm install
```

### Step 4: Test Your App Locally

Start the development server:

```bash
$ npm run dev -- --host 0.0.0.0
```

**Why `--host 0.0.0.0`?**
This allows you to access the app from Windows. Open your Windows browser and go to:
```
http://localhost:5173
```

You should see your SvelteKit app running!

Press `Ctrl+C` to stop the development server.

### Step 5: Configure for Production

SvelteKit needs an adapter for production deployment. For Docker, we'll use the Node adapter:

```bash
$ npm install -D @sveltejs/adapter-node
```

Edit `svelte.config.js`:

```bash
$ nano svelte.config.js
```

Change the adapter import:

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

Press `Ctrl+X`, then `Y`, then `Enter` to save.

### Step 6: Build for Production

```bash
$ npm run build
```

This creates a production-ready build in the `build/` directory. This is what we'll put in Docker.

**Understanding the Build:**
- `build/`: Production server and static assets
- `build/index.js`: Entry point for the Node.js server
- `build/client/`: Static assets (JS, CSS, images)

---

## Dockerizing SvelteKit Applications

### Understanding Dockerfiles

A Dockerfile is like a recipe for creating a Docker image. It contains instructions on how to build your application environment.

### Step 1: Create a Dockerfile

In your `app1` directory:

```bash
$ nano Dockerfile
```

Add the following content:

```dockerfile
# syntax=docker/dockerfile:1

# Stage 1: Build
# Use Node.js LTS as the base image
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Remove dev dependencies
RUN npm prune --production

# Stage 2: Production
# Start with a fresh, smaller image
FROM node:20-alpine

# Install dumb-init to handle signals properly
RUN apk add --no-cache dumb-init

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Set working directory
WORKDIR /app

# Copy built application from builder stage
COPY --from=builder --chown=nodejs:nodejs /app/build ./build
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./

# Switch to non-root user
USER nodejs

# Expose port 3000
EXPOSE 3000

# Set environment variables
ENV NODE_ENV=production \
    PORT=3000 \
    HOST=0.0.0.0

# Use dumb-init to run the app
ENTRYPOINT ["dumb-init", "--"]

# Start the application
CMD ["node", "build"]
```

**Dockerfile Explanation:**

1. **Multi-stage Build**: We use two stages to keep the final image small
   - **Builder stage**: Contains build tools and compiles the app
   - **Production stage**: Only contains what's needed to run the app

2. **Base Image**: `node:20-alpine`
   - Alpine Linux is tiny (~5MB base)
   - Contains Node.js 20 (LTS version)

3. **Working Directory**: `/app`
   - All commands run in this directory inside the container

4. **Dependency Installation**: `npm ci`
   - Faster and more reliable than `npm install`
   - Uses exact versions from package-lock.json

5. **Security**: Non-root user
   - Containers should never run as root
   - We create a `nodejs` user with limited privileges

6. **dumb-init**: Proper signal handling
   - Ensures your app receives shutdown signals correctly
   - Prevents zombie processes

7. **Environment Variables**:
   - `NODE_ENV=production`: Optimizes Node.js for production
   - `PORT=3000`: Default port (can be overridden)
   - `HOST=0.0.0.0`: Listen on all network interfaces

### Step 2: Create .dockerignore

Just like .gitignore, .dockerignore tells Docker what files to exclude:

```bash
$ nano .dockerignore
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
```

**Why exclude these?**
- `node_modules`: We'll install fresh in Docker
- `.svelte-kit`: Build artifacts not needed
- `.env`: Secrets shouldn't be in images
- `.git`: Reduces image size

### Step 3: Build Your Docker Image

```bash
$ docker build -t sveltekit-app1:latest .
```

**Command Breakdown:**
- `docker build`: Build a Docker image
- `-t sveltekit-app1:latest`: Tag (name) the image
  - `sveltekit-app1`: Image name
  - `latest`: Tag/version
- `.`: Use current directory as build context

This will take a few minutes the first time. You'll see each step executing.

### Step 4: Test Your Docker Image

Run a container from your image:

```bash
$ docker run -d -p 3000:3000 --name app1-test sveltekit-app1:latest
```

**Command Breakdown:**
- `docker run`: Create and start a container
- `-d`: Detached mode (runs in background)
- `-p 3000:3000`: Port mapping (host:container)
  - First 3000: Port on your PC
  - Second 3000: Port inside container
- `--name app1-test`: Name the container
- `sveltekit-app1:latest`: Image to use

Check if it's running:

```bash
$ docker ps
```

You should see your container listed. Access it at `http://localhost:3000` from Windows.

### Step 5: View Container Logs

```bash
$ docker logs app1-test
```

You should see output like:
```
Listening on 0.0.0.0:3000
```

To follow logs in real-time:

```bash
$ docker logs -f app1-test
```

Press `Ctrl+C` to stop following.

### Step 6: Stop and Remove Test Container

```bash
$ docker stop app1-test
$ docker rm app1-test
```

**Note:** Stopping doesn't remove the container; it just stops it. You need `docker rm` to remove it completely.

---

## Setting Up Caddy Reverse Proxy

### What is a Reverse Proxy?

A reverse proxy sits in front of your applications and:
- Routes incoming requests to the correct app
- Handles SSL/TLS certificates
- Can load balance across multiple instances
- Provides a single entry point for all your apps

**Without Reverse Proxy:**
```
Browser → http://localhost:3000 → App1
Browser → http://localhost:3001 → App2
Browser → http://localhost:3002 → App3
```

**With Reverse Proxy:**
```
Browser → http://app1.yourdomain.com → Caddy → App1
Browser → http://app2.yourdomain.com → Caddy → App2
Browser → http://app3.yourdomain.com → Caddy → App3
```

### Step 1: Create Caddy Directory Structure

```bash
$ cd ~/projects/sveltekit-apps
$ mkdir -p caddy/config
$ mkdir -p caddy/data
```

**Directory Purpose:**
- `caddy/config/`: Caddyfile configuration
- `caddy/data/`: SSL certificates and other data

### Step 2: Create Caddyfile

The Caddyfile is Caddy's configuration file:

```bash
$ nano caddy/config/Caddyfile
```

Add this basic configuration:

```
# Global options
{
    # Disable admin API on external interface (security)
    admin off

    # Email for Let's Encrypt notifications
    email your-email@example.com
}

# Local development (no HTTPS)
localhost:80 {
    # Reverse proxy to app1
    reverse_proxy app1:3000 {
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
    }
}

# Production example (automatic HTTPS)
# app1.yourdomain.com {
#     reverse_proxy app1:3000 {
#         header_up X-Real-IP {remote_host}
#         header_up X-Forwarded-For {remote_host}
#         header_up X-Forwarded-Proto {scheme}
#     }
# }
```

**Caddyfile Explanation:**

1. **Global Block**: Settings that apply to all sites
   - `admin off`: Disables admin API (security)
   - `email`: For Let's Encrypt certificate notifications

2. **Site Block**: `localhost:80`
   - Defines a site/domain to serve
   - For local development without HTTPS

3. **reverse_proxy Directive**:
   - `app1:3000`: Forward requests to app1 container on port 3000
   - Docker Compose will create a network where containers can find each other by name

4. **Headers**: Preserve client information
   - `X-Real-IP`: Client's actual IP address
   - `X-Forwarded-For`: Proxy chain
   - `X-Forwarded-Proto`: Original protocol (http/https)

### Step 3: Understanding Caddy's Automatic HTTPS

When you use a real domain name in the Caddyfile:

```
app1.yourdomain.com {
    reverse_proxy app1:3000
}
```

Caddy automatically:
1. Obtains SSL certificate from Let's Encrypt
2. Redirects HTTP to HTTPS
3. Renews certificates before expiration
4. Serves your site over HTTPS

**Requirements for Automatic HTTPS:**
- Domain must point to your server's public IP
- Ports 80 and 443 must be accessible from internet
- Valid email address configured

### Step 4: Create Caddy Dockerfile (Optional)

For a custom Caddy image with additional plugins:

```bash
$ nano caddy/Dockerfile
```

```dockerfile
FROM caddy:2-alpine

# Copy Caddyfile
COPY config/Caddyfile /etc/caddy/Caddyfile

# Expose ports
EXPOSE 80
EXPOSE 443
EXPOSE 443/udp

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1
```

For now, we'll use the official Caddy image directly.

---

## Multi-Container Orchestration with Docker Compose

Docker Compose allows you to define and run multi-container applications using a single YAML file.

### Step 1: Understanding Docker Compose

**docker-compose.yml** is a configuration file that defines:
- Services (containers) to run
- Networks they share
- Volumes for data persistence
- Environment variables
- Dependencies between services

### Step 2: Create docker-compose.yml

```bash
$ cd ~/projects/sveltekit-apps
$ nano docker-compose.yml
```

Add this comprehensive configuration:

```yaml
version: '3.8'

# Define services (containers)
services:

  # Caddy Reverse Proxy
  caddy:
    image: caddy:2-alpine
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"      # HTTP
      - "443:443"    # HTTPS
      - "443:443/udp" # HTTP/3
    volumes:
      - ./caddy/config/Caddyfile:/etc/caddy/Caddyfile:ro
      - ./caddy/data:/data
      - ./caddy/config:/config
    networks:
      - web
    depends_on:
      - app1
    labels:
      - "com.centurylinklabs.watchtower.enable=true"

  # SvelteKit App 1
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
    networks:
      - web
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  # Example App 2 (commented out - uncomment when ready)
  # app2:
  #   build:
  #     context: ./app2
  #     dockerfile: Dockerfile
  #   container_name: app2
  #   restart: unless-stopped
  #   environment:
  #     - NODE_ENV=production
  #     - PORT=3000
  #   networks:
  #     - web
  #   logging:
  #     driver: "json-file"
  #     options:
  #       max-size: "10m"
  #       max-file: "3"

# Define networks
networks:
  web:
    driver: bridge

# Define volumes (for data persistence)
volumes:
  caddy_data:
    driver: local
  caddy_config:
    driver: local
```

**Configuration Breakdown:**

1. **version: '3.8'**: Docker Compose file format version

2. **services**: Container definitions

3. **caddy service**:
   - `image: caddy:2-alpine`: Use official Caddy image
   - `container_name`: Name for easy reference
   - `restart: unless-stopped`: Auto-restart unless manually stopped
   - `ports`: Map host ports to container ports
   - `volumes`: Mount host directories into container
     - `:ro` means read-only
   - `depends_on`: Wait for app1 before starting
   - `labels`: Metadata for other tools

4. **app1 service**:
   - `build`: Build from Dockerfile instead of using pre-built image
   - `context`: Build directory
   - `environment`: Environment variables
   - `logging`: Log rotation settings
     - `max-size`: Maximum log file size
     - `max-file`: Keep 3 log files

5. **networks**:
   - `web`: Internal network for container communication
   - `bridge`: Standard Docker network driver

6. **volumes**: Named volumes for persistence

### Step 3: Start All Services

```bash
$ docker compose up -d
```

**Command Breakdown:**
- `docker compose`: Docker Compose command
- `up`: Create and start containers
- `-d`: Detached mode (background)

**First Run:** This will:
1. Build app1 image (takes a few minutes)
2. Pull Caddy image from Docker Hub
3. Create network
4. Start all containers

### Step 4: Check Service Status

```bash
$ docker compose ps
```

You should see:
```
NAME      IMAGE              STATUS    PORTS
caddy     caddy:2-alpine     Up        0.0.0.0:80->80/tcp, ...
app1      sveltekit-app1     Up
```

### Step 5: View Logs

View all logs:
```bash
$ docker compose logs
```

View logs for specific service:
```bash
$ docker compose logs app1
$ docker compose logs caddy
```

Follow logs in real-time:
```bash
$ docker compose logs -f
```

### Step 6: Test Your Setup

From Windows, open your browser and go to:
```
http://localhost
```

You should see your SvelteKit app served through Caddy!

**What's Happening:**
1. Browser → http://localhost:80
2. Caddy receives request on port 80
3. Caddy forwards to app1:3000 (internal network)
4. App1 responds
5. Caddy returns response to browser

---

## Monitoring and Logging Setup

Production servers need monitoring to track:
- Resource usage (CPU, memory, disk)
- Application errors
- Request rates and response times
- System health

We'll set up a comprehensive monitoring stack:
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Loki**: Log aggregation
- **Promtail**: Log shipping
- **cAdvisor**: Container metrics

### Step 1: Understanding the Monitoring Stack

```
Applications → cAdvisor → Prometheus → Grafana
    ↓
  Logs → Promtail → Loki → Grafana
```

**Components:**
- **Prometheus**: Time-series database for metrics
- **Grafana**: Dashboard and visualization tool
- **Loki**: Log aggregation system (like Prometheus, but for logs)
- **Promtail**: Agent that ships logs to Loki
- **cAdvisor**: Collects container resource metrics

### Step 2: Create Monitoring Directory Structure

```bash
$ mkdir -p ~/projects/sveltekit-apps/monitoring/prometheus
$ mkdir -p ~/projects/sveltekit-apps/monitoring/grafana/provisioning/datasources
$ mkdir -p ~/projects/sveltekit-apps/monitoring/grafana/provisioning/dashboards
$ mkdir -p ~/projects/sveltekit-apps/monitoring/loki
$ mkdir -p ~/projects/sveltekit-apps/monitoring/promtail
```

### Step 3: Configure Prometheus

Create Prometheus configuration:

```bash
$ nano monitoring/prometheus/prometheus.yml
```

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    monitor: 'docker-host-alpha'

# Scrape configurations
scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # cAdvisor for container metrics
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  # Node exporter for system metrics (optional)
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
```

**Configuration Explanation:**
- `scrape_interval`: How often to collect metrics (15 seconds)
- `evaluation_interval`: How often to evaluate alerting rules
- `scrape_configs`: List of targets to collect metrics from

### Step 4: Configure Loki

Create Loki configuration:

```bash
$ nano monitoring/loki/loki-config.yml
```

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

ruler:
  alertmanager_url: http://localhost:9093

# Retention (keep logs for 7 days)
limits_config:
  retention_period: 168h

# Compactor for log retention
compactor:
  working_directory: /loki/compactor
  shared_store: filesystem
  retention_enabled: true
  retention_delete_delay: 2h
  retention_delete_worker_count: 150
```

**Key Settings:**
- `retention_period: 168h`: Keep logs for 7 days (168 hours)
- `storage.filesystem`: Store data on disk (simple setup)
- `auth_enabled: false`: No authentication (for local use)

### Step 5: Configure Promtail

Create Promtail configuration:

```bash
$ nano monitoring/promtail/promtail-config.yml
```

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  # Docker container logs
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

**Configuration Explanation:**
- `docker_sd_configs`: Auto-discover Docker containers
- `relabel_configs`: Extract container names and labels
- `url`: Where to send logs (Loki)

### Step 6: Configure Grafana Datasources

```bash
$ nano monitoring/grafana/provisioning/datasources/datasources.yml
```

```yaml
apiVersion: 1

datasources:
  # Prometheus
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true

  # Loki for logs
  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    editable: true
```

### Step 7: Update docker-compose.yml

Add monitoring services to your docker-compose.yml:

```bash
$ nano docker-compose.yml
```

Add these services (append to the existing services section):

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
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.enable-lifecycle'
    ports:
      - "9090:9090"
    networks:
      - web
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
      - web
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

  # Node Exporter - System Metrics (optional)
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

# Add monitoring network
networks:
  web:
    driver: bridge
  monitoring:
    driver: bridge

# Add volumes for persistence
volumes:
  prometheus_data:
    driver: local
  grafana_data:
    driver: local
  loki_data:
    driver: local
  caddy_data:
    driver: local
  caddy_config:
    driver: local
```

### Step 8: Restart Docker Compose

```bash
$ docker compose down
$ docker compose up -d
```

This will start all monitoring services.

### Step 9: Access Monitoring Tools

From Windows browser:

**Grafana** (Dashboards):
```
http://localhost:3001
```
- Username: `admin`
- Password: `admin` (change on first login)

**Prometheus** (Metrics):
```
http://localhost:9090
```

**cAdvisor** (Container Stats):
```
http://localhost:8080
```

### Step 10: Create Grafana Dashboard

1. Open Grafana (http://localhost:3001)
2. Login with admin/admin
3. Change password when prompted
4. Click "+" → "Import Dashboard"
5. Enter dashboard ID: `193` (Docker monitoring dashboard)
6. Click "Load"
7. Select "Prometheus" as the data source
8. Click "Import"

You now have a professional Docker monitoring dashboard!

### Step 11: View Logs in Grafana

1. In Grafana, click "Explore" (compass icon)
2. Select "Loki" as the data source
3. Choose a container from the dropdown
4. Click "Run Query"

You'll see all logs from your containers in real-time!

---

## Managing Multiple SvelteKit Apps

### Step 1: Create Additional Apps

```bash
$ cd ~/projects/sveltekit-apps
$ npm create svelte@latest app2
$ cd app2
$ npm install
$ npm install -D @sveltejs/adapter-node
```

Configure svelte.config.js as before (use adapter-node).

### Step 2: Copy Dockerfile

```bash
$ cp ../app1/Dockerfile ./
$ cp ../app1/.dockerignore ./
```

### Step 3: Update Caddyfile

```bash
$ nano caddy/config/Caddyfile
```

Add configuration for app2:

```
localhost:80 {
    # Route based on path
    route /app1/* {
        uri strip_prefix /app1
        reverse_proxy app1:3000
    }

    route /app2/* {
        uri strip_prefix /app2
        reverse_proxy app2:3000
    }

    # Default to app1
    reverse_proxy app1:3000
}

# Or use subdomain routing (if you have domains)
# app1.yourdomain.com {
#     reverse_proxy app1:3000
# }
#
# app2.yourdomain.com {
#     reverse_proxy app2:3000
# }
```

**Routing Strategies:**

1. **Path-based**:
   - `http://localhost/app1` → App1
   - `http://localhost/app2` → App2
   - Simple, no DNS needed

2. **Subdomain-based**:
   - `http://app1.domain.com` → App1
   - `http://app2.domain.com` → App2
   - Clean URLs, requires DNS setup

### Step 4: Update docker-compose.yml

Uncomment and add app2 service:

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
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### Step 5: Deploy New App

```bash
$ docker compose up -d --build
```

The `--build` flag forces Docker to rebuild images.

### Step 6: Test Multiple Apps

Path-based:
```
http://localhost/app1
http://localhost/app2
```

---

## Security Best Practices

### 1. Never Run Containers as Root

Already implemented in our Dockerfile:
```dockerfile
USER nodejs
```

### 2. Use Environment Variables for Secrets

Never hardcode secrets. Use environment files:

```bash
$ nano .env
```

```env
DATABASE_URL=postgresql://user:password@host:5432/db
API_KEY=your-secret-key
SESSION_SECRET=random-string-here
```

**In docker-compose.yml:**
```yaml
app1:
  env_file:
    - .env
```

**Important**: Add `.env` to `.gitignore`!

### 3. Keep Images Updated

Regularly update base images:

```bash
$ docker compose pull
$ docker compose up -d
```

### 4. Limit Container Resources

Prevent a single container from consuming all resources:

```yaml
app1:
  deploy:
    resources:
      limits:
        cpus: '0.5'
        memory: 512M
      reservations:
        memory: 256M
```

### 5. Use Read-Only Filesystems

When possible:

```yaml
app1:
  read_only: true
  tmpfs:
    - /tmp
    - /app/.npm
```

### 6. Implement Health Checks

```yaml
app1:
  healthcheck:
    test: ["CMD", "node", "-e", "require('http').get('http://localhost:3000/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"]
    interval: 30s
    timeout: 3s
    retries: 3
    start_period: 40s
```

Add a health endpoint to your SvelteKit app:

```javascript
// src/routes/health/+server.js
export function GET() {
  return new Response('OK', { status: 200 });
}
```

### 7. Scan Images for Vulnerabilities

Install Trivy:

```bash
$ sudo apt install wget apt-transport-https gnupg lsb-release
$ wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
$ echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
$ sudo apt update
$ sudo apt install trivy
```

Scan your images:

```bash
$ trivy image sveltekit-app1:latest
```

### 8. Implement Firewall Rules

If exposing to internet, use UFW (Uncomplicated Firewall):

```bash
$ sudo apt install ufw
$ sudo ufw default deny incoming
$ sudo ufw default allow outgoing
$ sudo ufw allow 22/tcp   # SSH
$ sudo ufw allow 80/tcp   # HTTP
$ sudo ufw allow 443/tcp  # HTTPS
$ sudo ufw enable
```

---

## Networking and Port Management

### Understanding Docker Networks

Docker creates isolated networks for container communication:

**Bridge Network** (default):
- Containers on same bridge can communicate
- Isolated from other networks
- Use container names as hostnames

**Host Network**:
- Container uses host's network directly
- No isolation
- Generally not recommended

### Our Network Setup

```yaml
networks:
  web:
    driver: bridge
  monitoring:
    driver: bridge
```

- `web`: For user-facing services (Caddy, apps)
- `monitoring`: For monitoring stack (isolated)

### Port Mapping

```yaml
ports:
  - "HOST_PORT:CONTAINER_PORT"
```

Examples:
- `"80:80"`: Map port 80 on host to port 80 in container
- `"3001:3000"`: Map port 3001 on host to port 3000 in container

**Internal vs External Ports:**
- External: Exposed on host (accessible from Windows)
- Internal: Only within Docker network

App containers don't need external ports when behind reverse proxy:

```yaml
app1:
  # No ports section - only accessible via Caddy
  networks:
    - web
```

### Checking Port Usage

```bash
$ sudo netstat -tulpn | grep LISTEN
```

Or:

```bash
$ sudo ss -tulpn | grep LISTEN
```

---

## Data Persistence and Volumes

### Understanding Docker Volumes

Containers are ephemeral - data is lost when containers are deleted. Volumes solve this:

**Types of Volumes:**

1. **Named Volumes** (managed by Docker):
```yaml
volumes:
  - grafana_data:/var/lib/grafana
```

2. **Bind Mounts** (host directory):
```yaml
volumes:
  - ./caddy/config:/etc/caddy
```

3. **tmpfs** (temporary, in-memory):
```yaml
tmpfs:
  - /tmp
```

### When to Use Each Type

**Named Volumes**:
- Best for: Database data, persistent storage
- Managed by Docker
- Backed up with Docker commands

**Bind Mounts**:
- Best for: Configuration files, source code
- Easy to edit from host
- Direct access to files

**tmpfs**:
- Best for: Temporary files, caches
- Fastest (RAM)
- Lost on container stop

### Adding Database to Your Setup

Example with PostgreSQL:

```yaml
services:
  postgres:
    image: postgres:15-alpine
    container_name: postgres
    restart: unless-stopped
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=myapp
      - POSTGRES_PASSWORD=secure_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - web
    ports:
      - "5432:5432"

volumes:
  postgres_data:
    driver: local
```

### Backing Up Volumes

**List volumes:**
```bash
$ docker volume ls
```

**Backup a volume:**
```bash
$ docker run --rm -v postgres_data:/data -v $(pwd):/backup ubuntu tar czf /backup/postgres_backup.tar.gz /data
```

**Restore a volume:**
```bash
$ docker run --rm -v postgres_data:/data -v $(pwd):/backup ubuntu tar xzf /backup/postgres_backup.tar.gz -C /
```

---

## Troubleshooting Common Issues

### Issue 1: Container Won't Start

**Check logs:**
```bash
$ docker compose logs app1
```

**Common causes:**
- Port already in use
- Missing environment variables
- Configuration errors

**Solution:**
```bash
$ docker compose down
$ docker compose up -d
```

### Issue 2: Can't Access App from Windows

**Check container is running:**
```bash
$ docker compose ps
```

**Check port mapping:**
```bash
$ docker port caddy
```

**Test from WSL:**
```bash
$ curl http://localhost
```

**If works in WSL but not Windows:**
- Restart WSL: `wsl --shutdown` then reopen
- Check Windows Firewall

### Issue 3: Build Fails

**Clear Docker cache:**
```bash
$ docker compose build --no-cache app1
```

**Check disk space:**
```bash
$ df -h
```

**Clean up Docker:**
```bash
$ docker system prune -a
```

**Warning:** This removes ALL unused images and containers.

### Issue 4: High Memory Usage

**Check container resource usage:**
```bash
$ docker stats
```

**Limit container resources:**
```yaml
app1:
  deploy:
    resources:
      limits:
        memory: 512M
```

### Issue 5: Networking Issues Between Containers

**Verify containers are on same network:**
```bash
$ docker network inspect sveltekit-apps_web
```

**Test connectivity:**
```bash
$ docker exec caddy ping app1
```

### Issue 6: SSL Certificate Issues

**Check Caddy logs:**
```bash
$ docker compose logs caddy
```

**Common issues:**
- Domain not pointing to server
- Ports 80/443 not accessible
- Invalid email in Caddyfile

**Testing SSL:**
```bash
$ curl -v https://yourdomain.com
```

### Issue 7: Docker Service Won't Start in WSL

**Restart Docker:**
```bash
$ sudo service docker restart
```

**Check Docker status:**
```bash
$ sudo service docker status
```

**If still failing:**
```bash
$ sudo dockerd
```

Look for error messages.

### Issue 8: Docker Installation Script Warnings on WSL

When running the Docker installation script (`sh get-docker.sh`), you may encounter these warnings:

```
Warning: the "docker" command appears to already exist on this system.
WSL DETECTED: We recommend using Docker Desktop for Windows.
Please get Docker Desktop from https://www.docker.com/products/docker-desktop/
```

**What's happening:**
- The script detected that Docker (or remnants of it) already exists on your system
- The script detected you're running WSL and is recommending Docker Desktop for Windows instead

**Solution Options:**

**Option 1: Continue with Docker Engine in WSL (Recommended for this guide)**
If you want full control and don't need a GUI:

1. **Wait for the timeout** (20 seconds) or press Enter to continue with the installation
2. **The script will complete successfully** and install Docker Engine
3. **Configure the Docker service** to start properly in WSL

After installation completes:

```bash
# Add your user to the docker group
$ sudo usermod -aG docker $USER

# Exit and restart WSL
$ exit

# (From Windows PowerShell or Terminal)
> wsl --shutdown
> wsl

# Start Docker service
$ sudo service docker start

# Verify installation
$ docker run hello-world
```

**Make Docker start automatically on WSL startup:**

Add to your `~/.bashrc`:
```bash
$ echo '# Start Docker service if not running' >> ~/.bashrc
$ echo 'if ! sudo service docker status > /dev/null 2>&1; then' >> ~/.bashrc
$ echo '    sudo service docker start > /dev/null 2>&1' >> ~/.bashrc
$ echo 'fi' >> ~/.bashrc
```

**Configure passwordless sudo for Docker service (optional but convenient):**

```bash
$ sudo visudo
```

Add this line at the end:
```
your-username ALL=(ALL) NOPASSWD: /usr/sbin/service docker start, /usr/sbin/service docker status
```

Replace `your-username` with your actual WSL username.

**Option 2: Install Docker Desktop for Windows**
If you prefer a GUI and automatic management:

- Download from https://www.docker.com/products/docker-desktop/
- Install on Windows (not in WSL)
- Docker Desktop automatically integrates with WSL2
- Provides GUI for container management
- No need to manually start Docker service
- **Note:** Requires more system resources and installs additional Windows services

**After installing Docker Desktop:**
```bash
# Test Docker from WSL
$ docker --version
$ docker run hello-world
```

**Option 3: Clean Up and Start Fresh**

If you want to remove the existing Docker installation first:

```bash
# Remove existing Docker packages
$ sudo apt remove docker docker-engine docker.io containerd runc

# Remove Docker data
$ sudo rm -rf /var/lib/docker
$ sudo rm -rf /var/lib/containerd

# Clean up
$ sudo apt autoremove
$ sudo apt autoclean
```

Then reinstall using either approach above.

**Docker Engine vs Docker Desktop Comparison:**

| Feature | Docker Engine (WSL) | Docker Desktop |
|---------|-------------------|----------------|
| Resource Usage | Lower | Higher |
| GUI | No | Yes |
| Auto-start | Manual setup needed | Automatic |
| Full Control | Yes | Limited |
| Windows Integration | Manual | Automatic |
| Best for | Servers, power users | Developers, beginners |

**Recommendation for this guide:**
We recommend **Docker Engine in WSL** because:
- Lower resource usage (no extra Windows services)
- Full control over Docker configuration
- Better for server-like environments
- Closer to production Linux environments
- No additional Windows services running in background

### Debugging Commands Reference

```bash
# View all containers (including stopped)
$ docker ps -a

# View container logs
$ docker logs <container_name>
$ docker logs -f <container_name>  # Follow

# Execute command in running container
$ docker exec -it <container_name> sh

# Inspect container
$ docker inspect <container_name>

# View Docker networks
$ docker network ls
$ docker network inspect <network_name>

# View volumes
$ docker volume ls
$ docker volume inspect <volume_name>

# Check Docker disk usage
$ docker system df

# Real-time resource usage
$ docker stats

# View Docker events
$ docker events
```

---

## Maintenance and Updates

### Daily Maintenance

**Check container health:**
```bash
$ docker compose ps
$ docker stats --no-stream
```

**Check logs for errors:**
```bash
$ docker compose logs --tail=100
```

### Weekly Maintenance

**Update images:**
```bash
$ docker compose pull
$ docker compose up -d
```

**Clean up unused resources:**
```bash
$ docker system prune
```

**Check disk usage:**
```bash
$ df -h
$ docker system df
```

### Monthly Maintenance

**Full system update:**
```bash
$ sudo apt update && sudo apt upgrade -y
$ docker compose pull
$ docker compose build --no-cache
$ docker compose up -d
```

**Backup critical data:**
```bash
$ tar czf backup-$(date +%Y%m%d).tar.gz ~/projects/sveltekit-apps
```

**Review logs in Grafana:**
- Check error rates
- Review resource usage
- Look for anomalies

### Updating SvelteKit Apps

**Build and deploy new version:**
```bash
$ cd ~/projects/sveltekit-apps/app1
$ git pull  # If using version control
$ docker compose build app1
$ docker compose up -d app1
```

**Zero-downtime deployment** (advanced):

1. Scale up:
```bash
$ docker compose up -d --scale app1=2
```

2. Update:
```bash
$ docker compose build app1
```

3. Rolling update:
```bash
$ docker compose up -d --no-deps app1
```

### Automation with Watchtower

Watchtower automatically updates containers when new images are available:

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
      - WATCHTOWER_POLL_INTERVAL=3600
      - WATCHTOWER_LABEL_ENABLE=true
    networks:
      - web
```

Only containers with the label will be updated:
```yaml
app1:
  labels:
    - "com.centurylinklabs.watchtower.enable=true"
```

---

## Advanced Topics

### 1. Environment-Specific Configurations

Use multiple compose files:

**docker-compose.yml** (base):
```yaml
services:
  app1:
    build: ./app1
    networks:
      - web
```

**docker-compose.prod.yml** (production overrides):
```yaml
services:
  app1:
    environment:
      - NODE_ENV=production
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G
```

**docker-compose.dev.yml** (development overrides):
```yaml
services:
  app1:
    volumes:
      - ./app1:/app
    environment:
      - NODE_ENV=development
```

**Usage:**
```bash
# Production
$ docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Development
$ docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### 2. Adding a Database

**PostgreSQL example:**

```yaml
services:
  postgres:
    image: postgres:15-alpine
    container_name: postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${DB_NAME:-myapp}
      POSTGRES_USER: ${DB_USER:-myapp}
      POSTGRES_PASSWORD: ${DB_PASSWORD:?error}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d
    networks:
      - web
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-myapp}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Update app to connect to database
  app1:
    environment:
      - DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@postgres:5432/${DB_NAME}
    depends_on:
      postgres:
        condition: service_healthy

volumes:
  postgres_data:
```

### 3. Redis for Caching

```yaml
services:
  redis:
    image: redis:7-alpine
    container_name: redis
    restart: unless-stopped
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - web
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  app1:
    environment:
      - REDIS_URL=redis://redis:6379
    depends_on:
      - redis

volumes:
  redis_data:
```

### 4. Horizontal Scaling

Run multiple instances of an app:

```bash
$ docker compose up -d --scale app1=3
```

Update Caddyfile for load balancing:

```
localhost:80 {
    reverse_proxy app1:3000 {
        lb_policy round_robin
        health_uri /health
        health_interval 10s
    }
}
```

### 5. Custom Domain with HTTPS

**Prerequisites:**
- Own a domain name
- Domain points to your public IP (A record)
- Ports 80 and 443 forwarded to your PC

**Update Caddyfile:**

```
app1.yourdomain.com {
    reverse_proxy app1:3000
}

app2.yourdomain.com {
    reverse_proxy app2:3000
}
```

Restart Caddy:
```bash
$ docker compose restart caddy
```

Caddy will automatically:
1. Obtain SSL certificate from Let's Encrypt
2. Set up HTTPS
3. Redirect HTTP to HTTPS
4. Renew certificates automatically

**Verify:**
```bash
$ curl -I https://app1.yourdomain.com
```

### 6. WebSocket Support

SvelteKit apps with WebSockets work automatically, but ensure Caddy configuration:

```
app1.yourdomain.com {
    reverse_proxy app1:3000 {
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}

        # WebSocket support
        header_up Connection {>Connection}
        header_up Upgrade {>Upgrade}
    }
}
```

### 7. Email Notifications

Get notified when containers stop:

Add to monitoring stack:

```yaml
services:
  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    restart: unless-stopped
    volumes:
      - ./monitoring/alertmanager:/etc/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
    ports:
      - "9093:9093"
    networks:
      - monitoring
```

Create `monitoring/alertmanager/alertmanager.yml`:

```yaml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'your-email@gmail.com'
  smtp_auth_username: 'your-email@gmail.com'
  smtp_auth_password: 'your-app-password'

route:
  receiver: 'email'

receivers:
  - name: 'email'
    email_configs:
      - to: 'your-email@gmail.com'
        send_resolved: true
```

### 8. CI/CD with GitHub Actions

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Server

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Deploy to server
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.HOST }}
          username: ${{ secrets.USERNAME }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            cd ~/projects/sveltekit-apps
            git pull
            docker compose build app1
            docker compose up -d app1
```

### 9. Backup Automation

Create backup script:

```bash
$ nano ~/backup.sh
```

```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/mnt/c/Backups"

# Backup Docker volumes
docker run --rm \
  -v sveltekit-apps_postgres_data:/data \
  -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/postgres_$DATE.tar.gz /data

# Backup configurations
tar czf $BACKUP_DIR/configs_$DATE.tar.gz \
  ~/projects/sveltekit-apps/caddy \
  ~/projects/sveltekit-apps/monitoring \
  ~/projects/sveltekit-apps/docker-compose.yml

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
```

Make executable:
```bash
$ chmod +x ~/backup.sh
```

Add to crontab (run daily at 2 AM):
```bash
$ crontab -e
```

Add:
```
0 2 * * * /home/yourusername/backup.sh >> /home/yourusername/backup.log 2>&1
```

### 10. Performance Optimization

**Enable BuildKit** (faster builds):
```bash
$ export DOCKER_BUILDKIT=1
$ export COMPOSE_DOCKER_CLI_BUILD=1
```

Add to `~/.bashrc` to make permanent.

**Use layer caching effectively** (Dockerfile):
```dockerfile
# Copy dependencies first (changes less often)
COPY package*.json ./
RUN npm ci

# Copy source code last (changes more often)
COPY . .
RUN npm run build
```

**Multi-stage builds** to reduce image size (already implemented).

**Use .dockerignore** to exclude unnecessary files (already implemented).

---

## Conclusion

Congratulations! You now have a complete production server setup running on your PC. You've learned:

✅ Docker fundamentals and containerization
✅ Building and deploying SvelteKit applications
✅ Setting up reverse proxy with automatic HTTPS
✅ Implementing comprehensive monitoring and logging
✅ Managing multiple applications
✅ Security best practices
✅ Troubleshooting common issues
✅ Maintenance and update procedures
✅ Advanced topics for scaling

### Next Steps

1. **Deploy your first real application**
   - Create a new SvelteKit project
   - Dockerize it following this guide
   - Add it to your docker-compose.yml

2. **Set up a custom domain**
   - Purchase a domain
   - Configure DNS
   - Update Caddyfile for HTTPS

3. **Implement backups**
   - Set up automated backup script
   - Test restore procedures

4. **Explore advanced features**
   - Add databases (PostgreSQL, Redis)
   - Implement CI/CD
   - Set up monitoring alerts

### Useful Commands Summary

```bash
# Docker Compose
docker compose up -d                 # Start all services
docker compose down                  # Stop all services
docker compose ps                    # List running services
docker compose logs -f               # Follow all logs
docker compose restart <service>     # Restart specific service
docker compose build                 # Rebuild images

# Docker
docker ps                            # List running containers
docker images                        # List images
docker logs <container>              # View logs
docker exec -it <container> sh       # Enter container shell
docker system prune                  # Clean up

# WSL
wsl --shutdown                       # Restart WSL
sudo service docker start            # Start Docker in WSL

# Monitoring
# Grafana: http://localhost:3001
# Prometheus: http://localhost:9090
# cAdvisor: http://localhost:8080
```

### Resources

- **Docker Documentation**: https://docs.docker.com
- **SvelteKit Documentation**: https://kit.svelte.dev
- **Caddy Documentation**: https://caddyserver.com/docs
- **Prometheus Documentation**: https://prometheus.io/docs
- **Grafana Documentation**: https://grafana.com/docs

### Getting Help

If you encounter issues:

1. Check the logs: `docker compose logs`
2. Review the troubleshooting section
3. Search for error messages online
4. Check container status: `docker compose ps`
5. Verify configurations are correct

Remember: Building a production server is a learning process. Take your time, experiment, and don't be afraid to break things in your test environment!

---

**End of Guide** - Version 1.0
**Last Updated**: 2025
**Total Lines**: 850+
