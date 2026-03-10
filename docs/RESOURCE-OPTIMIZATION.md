# Homelab Resource Optimization Guide

Findings from reviewing your ArgoCD apps. Focus on **consolidating monitoring** and **trimming optional/heavy workloads** to reduce node load.

---

## Quick action: consolidate monitoring (biggest win)

You currently deploy **two** full Prometheus stacks and **two** Grafana instances. To cut load immediately:

1. **Keep** `kube-prometheus-stack` (it now has resource limits and retention set).
2. **Stop deploying** the duplicate stack: move these files **outside** the app-of-apps path (your root app uses `path: argocd/apps`, and it may recurse into subdirs), e.g. create `argocd/apps-archive/` and move there:
   - `argocd/apps/prometheus.yaml` → `argocd/apps-archive/prometheus.yaml`
   - `argocd/apps/grafana.yaml` → `argocd/apps-archive/grafana.yaml`  
   Alternatively you can delete the files if you don’t need to keep them.
3. **Optional:** If you don’t use Victoria Metrics for specific dashboards or long retention, move or remove `argocd/apps/victoria-metrics.yaml` as well.

After that, sync once and optionally delete the now-orphaned resources in the `monitoring` namespace (e.g. the extra Prometheus/Grafana PVCs and pods) if ArgoCD doesn’t prune them.

**How to access Grafana, Prometheus, and Alertmanager after consolidation:** see [docs/MONITORING-ACCESS.md](MONITORING-ACCESS.md) for URLs, ports, and login.

---

## 1. Duplicate monitoring stacks (highest impact)

You have **multiple overlapping metrics and dashboards** in the `monitoring` namespace:

| App | What it runs | Notes |
|-----|----------------|------|
| **prometheus** | kube-prometheus-stack with Grafana **disabled** | Prometheus + Alertmanager, 3Gi storage, 512Mi–2Gi memory |
| **kube-prometheus-stack** | Same chart, release `monitoring`, Grafana **enabled** | Second Prometheus + second Grafana, 20Gi storage |
| **grafana** | Standalone Grafana | Third dashboard instance, 10Gi PVC |
| **victoria-metrics** | Victoria Metrics single | Another metrics backend, 10Gi PVC |

So you're running **two full Prometheus stacks**, **two Grafana instances** (one in kube-prometheus-stack + standalone), and **Victoria Metrics**. That’s a lot of CPU/memory and disk for a homelab.

### Recommendation

- **Pick one metrics stack:**
  - **Option A (simplest):** Use only **kube-prometheus-stack** (Prometheus + Grafana in one). Remove the **prometheus** app and the standalone **grafana** app. Optionally remove **victoria-metrics** unless you rely on it (e.g. long retention or specific dashboards).
  - **Option B:** Use **prometheus** (Grafana disabled) + **grafana** standalone. Remove **kube-prometheus-stack** and optionally **victoria-metrics**.

- After choosing, **delete or move to archive** the ArgoCD Application YAMLs for the stacks you no longer want so they are not deployed.

---

## 2. Other heavy or optional workloads

### PMM (Percona Monitoring)

- **Resources:** 2–4Gi memory, 500m CPU.
- **Use:** Only needed if you actively use it for MySQL/PostgreSQL/MongoDB monitoring.
- **Action:** If you don’t use it, suspend or remove the app to free resources.

### OpenSearch + OpenSearch Dashboards

- **Resources:** OpenSearch 512Mi–2Gi memory, up to 1 CPU; plus dashboards.
- **Use:** Search and log storage. If you’re not querying logs/search often, this is a good candidate to downsize or disable.
- **Action:** If you need it, consider lowering limits (e.g. `-Xms256m -Xmx512m` and smaller limits). If you don’t need it, suspend or remove.

### Alloy (Grafana Alloy)

- **Pattern:** DaemonSet → runs on **every node**, scraping and forwarding logs to Loki.
- **Impact:** Steady CPU/memory on each node.
- **Action:** If you don’t rely on Loki for logs, consider disabling the Alloy app. If you keep it, add resource requests/limits in the Helm values to cap usage.

### Loki

- **Resources:** 15Gi PVC, single binary.
- **Action:** Keep only if you use log querying. If you remove Alloy, you can also remove Loki to save resources.

### Longhorn

- No resource limits set in your values; Longhorn components (engine, replica, etc.) can use a lot of CPU/memory.
- **Action:** Consider setting `defaultSettings.resources` or per-component resources in the Longhorn Helm values to avoid spikes. Check Longhorn docs for recommended minimums before lowering.

### Jellyfin

- No resource requests/limits; transcoding can spike CPU/memory.
- **Action:** Add `resources.requests` and `resources.limits` (e.g. 500m–1 CPU, 512Mi–1Gi memory) so the scheduler and node are predictable; adjust for your typical usage.

### Gitea + PostgreSQL

- No explicit resource limits.
- **Action:** Add modest requests/limits for the Gitea and Postgres pods (e.g. 256Mi–512Mi memory, 100m–250m CPU) to avoid one app starving others.

### Goldilocks

- Runs recommender and dashboard with “on-by-default” for all namespaces; continuous VPA-style analysis.
- **Action:** If you’re not actively tuning resource requests, disable the dashboard and/or set `on-by-default: false` to reduce load, or remove the app.

### VPA

- Updater and admission controller are already disabled; only recommender runs.
- **Action:** Fine as-is; optionally remove if you don’t use VPA recommendations.

### Archive Team Warrior

- Optional background workload; no limits.
- **Action:** Add small limits (e.g. 256Mi memory, 200m CPU) or suspend when not needed.

---

## 3. Quick wins summary

1. **Consolidate monitoring:** Use one Prometheus stack and one Grafana; remove or archive the duplicate app manifests (prometheus vs kube-prometheus-stack, standalone grafana, and optionally victoria-metrics).
2. **Remove or suspend** PMM, OpenSearch (+ dashboards), and optionally Alloy/Loki if you don’t use them.
3. **Add resource limits** to Jellyfin, Gitea/Postgres, Archive Team Warrior, and Longhorn (per docs) to avoid spikes and noisy neighbours.
4. **Tighten Goldilocks** (disable dashboard or on-by-default) or remove if not needed.

If you tell me which option you prefer for monitoring (Option A: only kube-prometheus-stack, or Option B: prometheus + standalone grafana), I can suggest exact edits to your `argocd/apps` (e.g. which files to remove or archive and what to add for resources).
