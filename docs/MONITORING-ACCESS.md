# Monitoring after consolidation: one stack, one place

After you keep **only** kube-prometheus-stack and stop deploying the duplicate Prometheus and Grafana apps, you still have **one Grafana**, **one Prometheus**, and **one Alertmanager**. They all live in the same stack and are exposed on NodePorts.

---

## 1. Do the consolidation (one-time)

1. Create a folder outside the app-of-apps path so ArgoCD stops deploying those apps:
   ```bash
   mkdir -p argocd/apps-archive
   ```
2. Move the duplicate app definitions there:
   ```bash
   mv argocd/apps/prometheus.yaml argocd/apps-archive/
   mv argocd/apps/grafana.yaml argocd/apps-archive/
   ```
3. Commit and push. ArgoCD will sync and remove the duplicate Prometheus and standalone Grafana. The **kube-prometheus-stack** app (release name `monitoring`) stays and provides everything below.

*(Optional: if you don’t use Victoria Metrics, you can also `mv argocd/apps/victoria-metrics.yaml argocd/apps-archive/`.)*

---

## 2. How to access the UIs

Use **any node IP** in your cluster (or the one you already use for other NodePorts, e.g. Homepage). Replace `<NODE_IP>` with that IP (e.g. `192.168.1.10`).

| What | URL | Notes |
|------|-----|--------|
| **Grafana** | `http://<NODE_IP>:31040` | Dashboards, explore Prometheus/Loki, etc. |
| **Prometheus** | `http://<NODE_IP>:30900` | Query metrics, targets, config. |
| **Alertmanager** | `http://<NODE_IP>:30903` | Alerts, silences, routing. |

Example: if your node IP is `192.168.1.50`:
- Grafana: **http://192.168.1.50:31040**
- Prometheus: **http://192.168.1.50:30900**
- Alertmanager: **http://192.168.1.50:30903**

---

## 3. Grafana login

- **Username:** `admin`
- **Password:** whatever you set in `kube-prometheus-stack` under `grafana.adminPassword` (in `argocd/apps/kube-prometheus-stack.yaml`).  
  Right now that value is `CHANGE-ME-STRONG-PASSWORD` — change it in the values and sync if you haven’t already.

First time you log in, Grafana may ask to change the password; you can do that in the UI.

---

## 4. Finding your node IP

- **From your machine (with kubectl):**
  ```bash
  kubectl get nodes -o wide
  ```
  Use the value in the **INTERNAL-IP** (or EXTERNAL-IP if you use it) column.

- If you already use **Homepage** at `http://<something>:31000`, that “something” is your node IP for all these NodePorts too.

---

## 5. What’s in the one stack

The **kube-prometheus-stack** (ArgoCD app name `kube-prometheus-stack`, Helm release `monitoring`) deploys:

- **Prometheus** – scrapes metrics (NodePort 30900)
- **Alertmanager** – handles alerts (NodePort 30903)
- **Grafana** – dashboards and explore (NodePort 31040)
- **Node exporters** – per-node metrics (no direct UI)
- **kube-state-metrics** – cluster state metrics (no direct UI)

So you don’t need to “create” Grafana or Prometheus separately; they’re already part of this one stack. After you move `prometheus.yaml` and `grafana.yaml` to `apps-archive`, this single deployment is the only one running, and you use the URLs above to access everything.
