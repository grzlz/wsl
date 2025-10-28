# System Architecture - Three Perspectives

## Diagram 1: High-Level General Architecture

This shows the big picture of how everything connects:

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

---

## Diagram 2: Detailed Docker Compose Architecture

This shows the complete production setup with all services:

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

---

## Diagram 3: Current Setup (Before Caddy) - Direct Port Exposure

This shows how your SvelteKit app currently works with ports directly exposed:

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

**How It Currently Works:**

1. **Docker Build Stage** (happens once):
   ```bash
   docker compose build
   ```
   - Copies SvelteKit source code into container
   - Runs `npm ci` to install dependencies
   - Runs `npm run build` to compile app
   - Creates production build in `build/` directory
   - Final image = Node.js + built app

2. **Docker Run Stage** (happens when you start):
   ```bash
   docker compose up -d
   ```
   - Container starts
   - Executes: `node build` (runs the built SvelteKit app)
   - SvelteKit Node server listens on `0.0.0.0:3000`
   - Docker maps container port 3000 → host port 3000
   - WSL2 forwards port 3000 to Windows

3. **Request Flow**:
   ```
   Browser → localhost:3000 → Windows → WSL2 → Docker → Container:3000 → Node.js → SvelteKit App → Response
   ```

**Problems with This Approach:**

❌ **No HTTPS** - Only HTTP (not secure)
❌ **Port Conflicts** - Each app needs unique port (3000, 3001, 3002...)
❌ **Ugly URLs** - Users must remember port numbers
❌ **No SSL Certificates** - Can't get Let's Encrypt certs
❌ **Direct Exposure** - App directly faces internet (less secure)
❌ **No Load Balancing** - Can't run multiple instances

---

## After Adding Caddy - The Improved Architecture

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

## Summary

**Three Diagrams Explained:**

1. **High-Level Architecture**: The 30,000-foot view of browser → Caddy → apps
2. **Detailed Docker Compose**: All services, ports, networks, and volumes in your stack
3. **Current vs Future**: How direct port exposure works now, and how Caddy improves it

**Ready to implement Caddy?** 🚀
