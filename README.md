# SvelteKit Production Server Setup

A complete, production-ready infrastructure for hosting SvelteKit applications on Windows using WSL2, Docker, and Caddy reverse proxy.

## Overview

This project transforms your Windows PC into a professional server environment capable of hosting multiple SvelteKit web applications with automatic HTTPS, monitoring, and logging capabilities.

### What This Project Provides

- **Production-Ready Architecture**: Multi-tier infrastructure with reverse proxy, load balancing, and container orchestration
- **Automatic HTTPS**: Free SSL certificates from Let's Encrypt with automatic renewal
- **Monitoring & Logging**: Comprehensive observability with Prometheus, Grafana, and Loki
- **Containerization**: Docker-based isolation and easy deployment
- **Scalability**: Support for multiple applications and horizontal scaling

---

## Architecture

This setup uses a three-tier architecture with Caddy reverse proxy as the entry point, multiple SvelteKit application containers, and a complete monitoring stack.

### High-Level Architecture

This diagram shows the big picture of how everything connects:

```mermaid
graph TB
    subgraph Internet["🌐 External World"]
        Browser["Web Browser<br/>(You or Users)"]
    end

    subgraph Windows["💻 Windows PC - Your Host Machine"]
        WinNet["Windows Network Layer<br/>Forwards ports to WSL2"]
    end

    subgraph WSL2["🐧 WSL2 - Ubuntu Linux Environment"]
        subgraph Docker["🐳 Docker Engine"]
            subgraph Network["Internal Docker Network"]
                Proxy["🚦 Caddy<br/>Reverse Proxy<br/><br/>EXPOSED PORTS:<br/>80 → HTTP<br/>443 → HTTPS"]

                Server1["🖥️ App Server 1<br/>SvelteKit Built App<br/><br/>INTERNAL ONLY:<br/>Port 3000"]

                Server2["🖥️ App Server 2<br/>SvelteKit Built App<br/><br/>INTERNAL ONLY:<br/>Port 3000"]

                ServerN["🖥️ App Server N<br/>SvelteKit Built App<br/><br/>INTERNAL ONLY:<br/>Port 3000"]
            end
        end
    end

    Browser <-->|"HTTP/HTTPS<br/>Port 80/443"| WinNet
    WinNet <-->|"Port Forward"| Proxy

    Proxy <-.->|"Internal Network<br/>app1:3000"| Server1
    Proxy <-.->|"Internal Network<br/>app2:3000"| Server2
    Proxy <-.->|"Internal Network<br/>appN:3000"| ServerN

    style Proxy fill:#ff9999,stroke:#333,stroke-width:4px
    style Server1 fill:#99ccff,stroke:#333,stroke-width:2px
    style Server2 fill:#99ccff,stroke:#333,stroke-width:2px
    style ServerN fill:#99ccff,stroke:#333,stroke-width:2px
    style Browser fill:#99ff99,stroke:#333,stroke-width:2px
```

**Key Points:**
- 🚦 **Only Caddy** exposes ports to the outside world (80, 443)
- 🖥️ **App servers** are hidden behind Caddy, accessible only internally
- 🔒 **Security**: Direct access to apps is impossible from outside
- 📡 **Routing**: Caddy decides which app handles each request

### Complete Docker Compose Architecture

This shows the full production setup with all services:

```mermaid
graph TB
    subgraph External["External Access Points"]
        User["👤 User Browser"]
        Dev["👨‍💻 Developer<br/>Monitoring Access"]
    end

    subgraph DockerCompose["docker-compose.yml - Complete Stack"]

        subgraph WebNetwork["🌐 Docker Network: 'web'"]

            Caddy["<b>CADDY</b><br/>━━━━━━━━━━<br/>Image: caddy:2-alpine<br/>Container: caddy<br/><br/>EXPOSED PORTS:<br/>• 80:80 (HTTP)<br/>• 443:443 (HTTPS)<br/>• 443:443/udp (HTTP/3)<br/><br/>VOLUMES:<br/>• Caddyfile config<br/>• SSL certificates<br/><br/>DEPENDS ON:<br/>• app1, app2, appN"]

            App1["<b>APP1</b><br/>━━━━━━━━━━<br/>Build: ./app1/Dockerfile<br/>Container: app1<br/><br/>NO EXPOSED PORTS<br/>Internal: 3000<br/><br/>ENV:<br/>• NODE_ENV=production<br/>• PORT=3000<br/>• HOST=0.0.0.0"]

            App2["<b>APP2</b><br/>━━━━━━━━━━<br/>Build: ./app2/Dockerfile<br/>Container: app2<br/><br/>NO EXPOSED PORTS<br/>Internal: 3000<br/><br/>ENV:<br/>• NODE_ENV=production<br/>• PORT=3000<br/>• HOST=0.0.0.0"]

        end

        subgraph MonitorNetwork["📊 Docker Network: 'monitoring'"]

            Prometheus["<b>PROMETHEUS</b><br/>━━━━━━━━━━<br/>Image: prom/prometheus<br/><br/>EXPOSED PORT:<br/>• 9090:9090<br/><br/>Collects metrics"]

            Grafana["<b>GRAFANA</b><br/>━━━━━━━━━━<br/>Image: grafana/grafana<br/><br/>EXPOSED PORT:<br/>• 3001:3000<br/><br/>Dashboards & Viz"]

            Loki["<b>LOKI</b><br/>━━━━━━━━━━<br/>Image: grafana/loki<br/><br/>EXPOSED PORT:<br/>• 3100:3100<br/><br/>Log aggregation"]

            Promtail["<b>PROMTAIL</b><br/>━━━━━━━━━━<br/>Image: grafana/promtail<br/><br/>NO EXPOSED PORTS<br/><br/>Ships logs to Loki"]

            cAdvisor["<b>CADVISOR</b><br/>━━━━━━━━━━<br/>Image: cadvisor/cadvisor<br/><br/>EXPOSED PORT:<br/>• 8080:8080<br/><br/>Container metrics"]

        end

        subgraph Volumes["💾 Named Volumes (Persistent Data)"]
            Vol1["caddy_data<br/>(SSL certs)"]
            Vol2["caddy_config<br/>(Caddy configs)"]
            Vol3["prometheus_data<br/>(Metrics DB)"]
            Vol4["grafana_data<br/>(Dashboards)"]
            Vol5["loki_data<br/>(Logs DB)"]
        end

    end

    User -->|"Port 80/443"| Caddy
    Dev -->|"Port 3001"| Grafana
    Dev -->|"Port 9090"| Prometheus

    Caddy -->|"app1:3000"| App1
    Caddy -->|"app2:3000"| App2

    App1 -.->|"metrics"| Prometheus
    App2 -.->|"metrics"| Prometheus
    App1 -.->|"logs"| Promtail
    App2 -.->|"logs"| Promtail

    Promtail --> Loki
    cAdvisor --> Prometheus

    Prometheus --> Grafana
    Loki --> Grafana

    Caddy -.->|"persist"| Vol1
    Caddy -.->|"persist"| Vol2
    Prometheus -.->|"persist"| Vol3
    Grafana -.->|"persist"| Vol4
    Loki -.->|"persist"| Vol5

    style Caddy fill:#ff9999,stroke:#333,stroke-width:4px
    style App1 fill:#99ccff,stroke:#333,stroke-width:2px
    style App2 fill:#99ccff,stroke:#333,stroke-width:2px
    style Grafana fill:#ffcc99,stroke:#333,stroke-width:2px
    style Prometheus fill:#ffcc99,stroke:#333,stroke-width:2px
    style Loki fill:#ffcc99,stroke:#333,stroke-width:2px
```

**Services Breakdown:**

| Service | Purpose | Exposed Ports | Access From Windows |
|---------|---------|---------------|---------------------|
| **Caddy** | Reverse Proxy | 80, 443 | `http://localhost` |
| **app1** | SvelteKit App 1 | NONE | Via Caddy only |
| **app2** | SvelteKit App 2 | NONE | Via Caddy only |
| **Grafana** | Monitoring UI | 3001 | `http://localhost:3001` |
| **Prometheus** | Metrics DB | 9090 | `http://localhost:9090` |
| **Loki** | Log Storage | 3100 | Internal only |
| **Promtail** | Log Collector | NONE | Internal only |
| **cAdvisor** | Container Stats | 8080 | `http://localhost:8080` |

### Before vs After: Understanding the Improvement

**Current Setup (Before Caddy) - Direct Port Exposure:**

```mermaid
graph TB
    subgraph Current["⚠️ CURRENT SETUP - Before Adding Caddy"]

        Browser["🌐 Browser"]

        subgraph Windows["Windows PC"]
            WinPort["Windows Network<br/>localhost:3000"]
        end

        subgraph WSL["WSL2"]
            subgraph DockerOld["Docker"]
                AppDirect["<b>SvelteKit App Container</b><br/>━━━━━━━━━━━━━━━━━━<br/><br/>Build Process:<br/>1. npm ci (install deps)<br/>2. npm run build (compile)<br/>3. Output: build/ folder<br/><br/>Runtime:<br/>• Runs: node build/index.js<br/>• Listens: 0.0.0.0:3000<br/><br/>EXPOSED PORT:<br/>• 3000:3000<br/><br/>docker-compose.yml:<br/>  ports:<br/>    - '3000:3000'"]
            end
        end

    end

    Browser -->|"http://localhost:3000"| WinPort
    WinPort -->|"Port mapping<br/>3000:3000"| AppDirect
    AppDirect -->|"HTTP Response"| WinPort
    WinPort -->|"Response"| Browser

    style AppDirect fill:#ffff99,stroke:#f90,stroke-width:3px
    style Browser fill:#99ff99,stroke:#333,stroke-width:2px
```

**Problems with This Approach:**

❌ **No HTTPS** - Only HTTP (not secure)
❌ **Port Conflicts** - Each app needs unique port (3000, 3001, 3002...)
❌ **Ugly URLs** - Users must remember port numbers
❌ **No SSL Certificates** - Can't get Let's Encrypt certs
❌ **Direct Exposure** - App directly faces internet (less secure)
❌ **No Load Balancing** - Can't run multiple instances

**Improved Setup (With Caddy):**

```mermaid
graph TB
    subgraph Future["✅ WITH CADDY - Improved Setup"]

        BrowserNew["🌐 Browser"]

        subgraph WindowsNew["Windows PC"]
            WinPort80["Windows Network<br/>localhost:80"]
            WinPort443["Windows Network<br/>localhost:443"]
        end

        subgraph WSLNew["WSL2"]
            subgraph DockerNew["Docker"]

                CaddyNew["<b>Caddy Container</b><br/>━━━━━━━━━━━━━<br/><br/>• Handles HTTPS<br/>• SSL Certificates<br/>• Routes requests<br/><br/>EXPOSED:<br/>• 80:80<br/>• 443:443"]

                App1New["<b>App1</b><br/>━━━━━━━<br/><br/>Internal only<br/>Port: 3000<br/><br/>NO EXPOSED<br/>PORTS"]

                App2New["<b>App2</b><br/>━━━━━━━<br/><br/>Internal only<br/>Port: 3000<br/><br/>NO EXPOSED<br/>PORTS"]

            end
        end

    end

    BrowserNew -->|"http://localhost/app1<br/>OR<br/>https://app1.domain.com"| WinPort80
    WinPort80 --> CaddyNew
    WinPort443 --> CaddyNew

    CaddyNew -->|"Route: /app1/*<br/>→ app1:3000"| App1New
    CaddyNew -->|"Route: /app2/*<br/>→ app2:3000"| App2New

    style CaddyNew fill:#ff9999,stroke:#333,stroke-width:4px
    style App1New fill:#99ccff,stroke:#333,stroke-width:2px
    style App2New fill:#99ccff,stroke:#333,stroke-width:2px
    style BrowserNew fill:#99ff99,stroke:#333,stroke-width:2px
```

**Benefits with Caddy:**

✅ **Automatic HTTPS** - Free SSL certificates
✅ **Single Port** - Everything through port 80/443
✅ **Clean URLs** - `app1.domain.com` or `localhost/app1`
✅ **Security** - Apps hidden behind proxy
✅ **Load Balancing** - Can run multiple app instances
✅ **Professional** - Production-ready setup

---

## Quick Start

### Prerequisites

- Windows PC with WSL2 installed
- At least 20GB free disk space
- Administrator access to your PC

### Installation Steps

1. **Clone or download this repository**
   ```bash
   cd ~/projects
   git clone <your-repo-url> sveltekit-apps
   cd sveltekit-apps
   ```

2. **Install Docker in WSL2**
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo usermod -aG docker $USER
   ```

3. **Start Docker service**
   ```bash
   sudo service docker start
   ```

4. **Deploy the stack**
   ```bash
   docker compose up -d
   ```

5. **Access your application**
   - Main app: `http://localhost`
   - Grafana monitoring: `http://localhost:3001`
   - Prometheus metrics: `http://localhost:9090`

For detailed step-by-step instructions, see **[NEXT-STEPS.md](NEXT-STEPS.md)**.

---

## Documentation

This project includes comprehensive documentation:

- **[README.md](README.md)** (this file) - Overview and architecture
- **[GUIDE.md](GUIDE.md)** - Complete implementation guide with detailed explanations
- **[NEXT-STEPS.md](NEXT-STEPS.md)** - Step-by-step instructions to deploy the stack
- **[architecture-diagrams.md](architecture-diagrams.md)** - Detailed architecture diagrams and explanations

---

## Project Structure

```
sveltekit-apps/
├── README.md                          # This file
├── GUIDE.md                           # Complete guide
├── NEXT-STEPS.md                      # Implementation steps
├── architecture-diagrams.md           # Architecture diagrams
├── docker-compose.yml                 # Main orchestration file
│
├── caddy/                             # Caddy reverse proxy
│   ├── config/
│   │   └── Caddyfile                 # Caddy configuration
│   └── data/                          # SSL certificates (auto-generated)
│
├── app1/                              # First SvelteKit application
│   ├── src/                           # SvelteKit source code
│   ├── Dockerfile                     # Container definition
│   ├── package.json                   # Node.js dependencies
│   └── svelte.config.js              # SvelteKit configuration
│
├── app2/                              # Second SvelteKit application
│   └── ...                            # (Same structure as app1)
│
└── monitoring/                        # Monitoring & logging stack
    ├── prometheus/
    │   └── prometheus.yml            # Metrics collection config
    ├── grafana/
    │   └── provisioning/             # Grafana datasources
    ├── loki/
    │   └── loki-config.yml          # Log aggregation config
    └── promtail/
        └── promtail-config.yml      # Log shipping config
```

---

## Features

### Core Features

- **Reverse Proxy**: Caddy handles all incoming traffic
- **Automatic HTTPS**: Free SSL certificates from Let's Encrypt
- **Multi-App Support**: Host multiple SvelteKit applications
- **Container Isolation**: Each app runs in its own container
- **Production-Ready**: Optimized Dockerfiles with multi-stage builds

### Monitoring & Observability

- **Prometheus**: Time-series metrics database
- **Grafana**: Beautiful dashboards and visualization
- **Loki**: Log aggregation and querying
- **Promtail**: Automatic log collection from containers
- **cAdvisor**: Container resource usage metrics

### Security Features

- **Non-root containers**: Apps run as unprivileged users
- **Read-only filesystems**: Where applicable
- **Resource limits**: CPU and memory constraints
- **Network isolation**: Separate networks for web and monitoring
- **Health checks**: Automatic container health monitoring

---

## Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Host OS** | Windows + WSL2 | Development environment |
| **Container Runtime** | Docker Engine | Container orchestration |
| **Reverse Proxy** | Caddy 2 | HTTP/HTTPS routing, SSL |
| **Web Framework** | SvelteKit | Application framework |
| **Runtime** | Node.js 20 LTS | JavaScript runtime |
| **Metrics** | Prometheus | Time-series database |
| **Visualization** | Grafana | Dashboards & alerts |
| **Logs** | Loki + Promtail | Log aggregation |
| **Container Metrics** | cAdvisor | Resource monitoring |

---

## Usage

### Starting the Stack

```bash
# Start all services
docker compose up -d

# Start specific service
docker compose up -d caddy

# Start with rebuild
docker compose up -d --build
```

### Viewing Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f app1

# Last 100 lines
docker compose logs --tail=100
```

### Stopping the Stack

```bash
# Stop all services
docker compose down

# Stop and remove volumes (data loss!)
docker compose down -v
```

### Updating Applications

```bash
# Rebuild and restart specific app
docker compose build app1
docker compose up -d app1

# Rebuild everything
docker compose build
docker compose up -d
```

---

## Accessing Services

Once deployed, access these services from your Windows browser:

| Service | URL | Credentials |
|---------|-----|-------------|
| **Main App** | http://localhost | N/A |
| **Grafana** | http://localhost:3001 | admin / admin |
| **Prometheus** | http://localhost:9090 | N/A |
| **cAdvisor** | http://localhost:8080 | N/A |

---

## Customization

### Adding a New SvelteKit App

1. Create new app directory
2. Copy Dockerfile from existing app
3. Add service to `docker-compose.yml`
4. Update `caddy/config/Caddyfile` with routing
5. Deploy: `docker compose up -d --build`

### Configuring Domain Names

Edit `caddy/config/Caddyfile`:

```caddyfile
yourdomain.com {
    reverse_proxy app1:3000
}

app2.yourdomain.com {
    reverse_proxy app2:3000
}
```

Caddy automatically obtains SSL certificates for your domains.

### Environment Variables

Create `.env` file in project root:

```env
NODE_ENV=production
DATABASE_URL=postgresql://user:pass@host:5432/db
API_KEY=your-secret-key
```

Add to service in `docker-compose.yml`:

```yaml
app1:
  env_file:
    - .env
```

---

## Maintenance

### Regular Tasks

**Daily:**
- Check container health: `docker compose ps`
- Review logs: `docker compose logs --tail=100`

**Weekly:**
- Update images: `docker compose pull`
- Clean up: `docker system prune`

**Monthly:**
- Full system update: `sudo apt update && sudo apt upgrade`
- Backup configurations and volumes
- Review Grafana dashboards for anomalies

### Backup Strategy

Backup script example:

```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/mnt/c/Backups"

# Backup configurations
tar czf $BACKUP_DIR/configs_$DATE.tar.gz \
  caddy/ monitoring/ docker-compose.yml .env

# Backup Docker volumes
docker run --rm \
  -v caddy_data:/data \
  -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/caddy_data_$DATE.tar.gz /data
```

---

## Troubleshooting

### Common Issues

**Container won't start:**
```bash
docker compose logs <service-name>
docker compose down && docker compose up -d
```

**Can't access from Windows:**
```bash
# Restart WSL from Windows PowerShell
wsl --shutdown
wsl
sudo service docker start
docker compose up -d
```

**Port already in use:**
```bash
sudo netstat -tulpn | grep :<port>
# Kill the process or change port in docker-compose.yml
```

**Build failures:**
```bash
docker system prune -a
docker compose build --no-cache
```

For more troubleshooting tips, see [GUIDE.md](GUIDE.md#troubleshooting-common-issues).

---

## Performance Optimization

### Resource Limits

Set resource limits in `docker-compose.yml`:

```yaml
app1:
  deploy:
    resources:
      limits:
        cpus: '1.0'
        memory: 512M
      reservations:
        cpus: '0.25'
        memory: 256M
```

### Horizontal Scaling

Run multiple instances of an app:

```bash
docker compose up -d --scale app1=3
```

Configure load balancing in Caddyfile:

```caddyfile
localhost:80 {
    reverse_proxy app1:3000 {
        lb_policy round_robin
        health_uri /health
    }
}
```

---

## Security Considerations

### Best Practices Implemented

✅ Non-root containers
✅ Multi-stage Docker builds
✅ Resource limits
✅ Health checks
✅ Network isolation
✅ Read-only configurations
✅ Log rotation
✅ Automatic SSL/TLS

### Additional Recommendations

- Keep Docker and images updated
- Use strong passwords for services
- Enable firewall (UFW) on WSL
- Regular security audits with `trivy`
- Monitor logs for suspicious activity

---

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

## License

This project is provided as-is for educational and development purposes.

---

## Resources

- **Docker Documentation**: https://docs.docker.com
- **SvelteKit Documentation**: https://kit.svelte.dev
- **Caddy Documentation**: https://caddyserver.com/docs
- **Prometheus Documentation**: https://prometheus.io/docs
- **Grafana Documentation**: https://grafana.com/docs

---

## Support

For issues or questions:

1. Check [GUIDE.md](GUIDE.md) for detailed explanations
2. Review [NEXT-STEPS.md](NEXT-STEPS.md) for implementation help
3. Check logs: `docker compose logs`
4. Search existing issues on GitHub

---

## Acknowledgments

This project leverages open-source technologies:

- Caddy Server
- Docker & Docker Compose
- SvelteKit
- Prometheus & Grafana
- Loki & Promtail
- cAdvisor

---

**Built with ❤️ for production-ready SvelteKit hosting**
