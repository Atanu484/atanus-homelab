# Atanu's Homelab

My personal homelab — a bare-metal Kubernetes cluster I tinker with at home. Everything here is self-hosted, version-controlled, and deployed through GitOps. Started as a way to learn k8s properly and kind of snowballed into this.

## How it's built

Running [Kubernetes](https://kubernetes.io/) v1.35.0 on [Talos Linux](https://www.talos.dev/) — Talos is an immutable, API-only OS built specifically for k8s, no SSH, no package manager, config is applied via files. Takes a bit to get used to but it's really solid once it clicks.

Everything is deployed through [ArgoCD](https://argo-cd.readthedocs.io/) using the App-of-Apps pattern — this repo is the source of truth. Push a change, ArgoCD picks it up. No manual `kubectl apply` anywhere.

| Layer | What I'm using |
|-------|---------------|
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/talos.png" width="18"> OS | [Talos Linux](https://www.talos.dev/) — immutable, no SSH |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/kubernetes.png" width="18"> Orchestration | [Kubernetes](https://kubernetes.io/) v1.35.0 |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/argo-cd.png" width="18"> GitOps | [ArgoCD](https://argo-cd.readthedocs.io/) — App-of-Apps |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/traefik.png" width="18"> Ingress | [Traefik](https://traefik.io/) with auto HTTPS |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/longhorn.png" width="18"> Storage | [Longhorn](https://longhorn.io/) + [MinIO](https://min.io/) for S3 |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/cert-manager.png" width="18"> TLS | [cert-manager](https://cert-manager.io/) |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/kubernetes.png" width="18"> Secrets | [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) — encrypted in Git |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/renovate.png" width="18"> Updates | [Renovate](https://github.com/renovatebot/renovate) — runs in GitHub Actions (daily); add repo secret `RENOVATE_TOKEN` (PAT with `repo` scope) |

## What's running

### Platform & Networking

| App | What it does |
|-----|-------------|
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/argo-cd.png" width="18"> [ArgoCD](https://argo-cd.readthedocs.io/) | Watches this repo and keeps the cluster in sync |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/traefik.png" width="18"> [Traefik](https://traefik.io/) | Handles all ingress and terminates TLS |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/cert-manager.png" width="18"> [cert-manager](https://cert-manager.io/) | Auto-renews TLS certs, forget it exists |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/kubernetes.png" width="18"> [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) | Lets me commit encrypted secrets to Git safely |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/pi-hole.png" width="18"> [Pi-hole](https://pi-hole.net/) | DNS-level ad blocking for the whole network |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/coredns.png" width="18"> [CoreDNS](https://coredns.io/) | Cluster DNS with some custom overrides |

### Storage

| App | What it does |
|-----|-------------|
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/longhorn.png" width="18"> [Longhorn](https://longhorn.io/) | Distributed block storage — handles PVCs across nodes |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/minio.png" width="18"> [MinIO](https://min.io/) | S3-compatible storage, mostly used for backups |

### Observability

| App | What it does |
|-----|-------------|
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/prometheus.png" width="18"> [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) | Prometheus, Alertmanager, node exporters, the works |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/grafana.png" width="18"> [Grafana](https://grafana.com/) | Where I actually look at all the metrics |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/loki.png" width="18"> [Loki](https://grafana.com/oss/loki/) | Log aggregation, pairs with Grafana |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/alloy.png" width="18"> [Grafana Alloy](https://grafana.com/oss/alloy-opentelemetry-collector/) | Ships logs and traces to Loki/Tempo |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/victoriametrics.png" width="18"> [VictoriaMetrics](https://victoriametrics.com/) | Long-term metrics storage |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/opensearch.png" width="18"> [OpenSearch](https://opensearch.org/) + Dashboards | Log search when Loki isn't enough |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/uptime-kuma.png" width="18"> [Uptime Kuma](https://github.com/louislam/uptime-kuma) | Keeps an eye on all my services |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/kubernetes.png" width="18"> [PMM](https://www.percona.com/software/database-tools/percona-monitoring-and-management) | Database monitoring |

### Security & Identity

| App | What it does |
|-----|-------------|
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/keycloak.png" width="18"> [Keycloak](https://www.keycloak.org/) | SSO for everything — OIDC, SAML, the lot |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/vaultwarden.png" width="18"> [Vaultwarden](https://github.com/dani-garcia/vaultwarden) | Self-hosted Bitwarden, been using it for years |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/kubernetes.png" width="18"> [Falco](https://falco.org/) | Runtime security, alerts on sketchy syscalls |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/kubernetes.png" width="18"> [Trivy](https://trivy.dev/) | Container & workload scanning (CVEs, misconfig, secrets); reports as CRDs + CI on this repo |

### Cluster Management

| App | What it does |
|-----|-------------|
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/kubernetes.png" width="18"> [Goldilocks](https://github.com/FairwindsOps/goldilocks) | Tells me if my resource requests are too high/low |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/kubernetes.png" width="18"> [VPA](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler) | Automatically right-sizes pod resources |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/kubernetes.png" width="18"> [Descheduler](https://github.com/kubernetes-sigs/descheduler) | Moves pods around to keep nodes balanced |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/kubernetes.png" width="18"> [Metrics Server](https://github.com/kubernetes-sigs/metrics-server) | Needed for `kubectl top` and HPA |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/portainer.png" width="18"> [Portainer](https://www.portainer.io/) | GUI for when I don't feel like typing kubectl |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/renovate.png" width="18"> [Renovate](https://github.com/renovatebot/renovate) | Opens PRs whenever a Helm chart has a new version |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/terraform.png" width="18"> [Atlantis](https://www.runatlantis.io/) | Runs Terraform plans/applies on PRs |

### Productivity

| App | What it does |
|-----|-------------|
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/paperless-ngx.png" width="18"> [Paperless-ngx](https://docs.paperless-ngx.com/) | Scan, OCR and search all my documents |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/memos.png" width="18"> [Memos](https://usememos.com/) | Quick notes, like a self-hosted Twitter for myself |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/commafeed.png" width="18"> [CommaFeed](https://www.commafeed.com/) | RSS reader, don't want an algorithm deciding what I read |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/karakeep.png" width="18"> [KaraKeep](https://karakeep.app/) | Bookmark manager, replaces my messy browser bookmarks |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/searxng.png" width="18"> [SearXNG](https://searxng.github.io/searxng/) | Private search engine, aggregates results without tracking |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/wakapi.png" width="18"> [Wakapi](https://wakapi.dev/) | Tracks how long I spend in each project/language |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/myspeed.png" width="18"> [MySpeed](https://myspeed.dev/) | Logs internet speed over time, useful for ISP complaints |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/kubernetes.png" width="18"> [Vesta](https://github.com/vesta-finance/vesta-finance) | Finance tracking |

### Media

| App | What it does |
|-----|-------------|
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/jellyfin.png" width="18"> [Jellyfin](https://jellyfin.org/) | Media server for movies and TV |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/metube.png" width="18"> [MeTube](https://github.com/alexta69/metube) | yt-dlp with a web UI |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/filebrowser.png" width="18"> [Miniserve](https://github.com/svenstaro/miniserve) | Quickly serve files over HTTP |

### Dev stuff

| App | What it does |
|-----|-------------|
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/gitea.png" width="18"> [Gitea](https://gitea.io/) | Self-hosted Git, mirror of my GitHub repos |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/ntfy.png" width="18"> [ntfy](https://ntfy.sh/) | Push notifications — alerts, cronjob failures, etc |

### Dashboards

| App | What it does |
|-----|-------------|
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/homepage.png" width="18"> [Homepage](https://gethomepage.dev/) | Main dashboard, shows status of everything |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/homarr.png" width="18"> [Homarr](https://homarr.dev/) | Another dashboard, I haven't picked one yet |
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/glance.png" width="18"> [Glance](https://github.com/glanceapp/glance) | Feed dashboard — news, weather, stocks |

### Just for fun

| App | What it does |
|-----|-------------|
| <img src="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/kubernetes.png" width="18"> [Archive Team Warrior](https://wiki.archiveteam.org/index.php/ArchiveTeam_Warrior) | Contributes spare CPU/bandwidth to archiving the web |

## Repo layout

```
atanus-homelab/
├── argocd/
│   ├── root-app.yaml       # bootstrap — apply this once to get everything else
│   └── apps/               # one file per app (includes trivy-operator for in-cluster scanning)
│       └── argocd.yaml     # Argo CD self-management (Argo deploys itself from Helm)
├── .github/workflows/      # CI: Renovate (daily), Trivy (push/PR + weekly)
├── coredns.yaml            # custom CoreDNS config
└── renovate.json           # Renovate config
```

The whole thing is driven by ArgoCD's App-of-Apps pattern. You apply `root-app.yaml` once, and ArgoCD takes it from there — syncing, pruning, and healing automatically. Adding a new app is just dropping a new file in `argocd/apps/`.

**Argo CD self-management:** The `argocd` app in `argocd/apps/argocd.yaml` deploys Argo CD from the official Helm chart so Argo CD manages its own workloads (server, repo-server, controller, redis). After you push this file, sync the root-app; it will create the `argocd` Application, which then syncs the chart. If you had a manual install with customizations, add them to the `values` block in that file (or use a values file) before syncing.
