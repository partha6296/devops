# GitOps & Argo CD Platform

This directory contains the Helm charts, environment overlays, observability stack manifests, and Argo CD Application manifests for managing the Task Management microservice platform on Kubernetes / Amazon EKS.

---

## 📁 Directory Layout

```text
gitops/
├── charts/
│   └── microservice/               # Reusable production Helm chart
│       ├── Chart.yaml
│       ├── values.yaml             # Baseline values (includes metrics annotations)
│       └── templates/              # Deployment, Service, Ingress (ALB), HPA, SA, ConfigMap
│
├── environments/
│   └── dev/
│       ├── user-service-values.yaml
│       ├── task-service-values.yaml
│       ├── notification-service-values.yaml
│       ├── frontend-values.yaml    # Includes Ingress definition for AWS ALB
│       └── postgres.yaml           # Dev database deployment
│
├── observability/                  # Cloud-native Observability Stack (monitoring namespace)
│   ├── 00-namespace.yaml           # monitoring namespace
│   ├── prometheus/                 # Time-series metrics collection & scraping
│   │   ├── clusterrole.yaml        # ServiceAccount & ClusterRole for Kubernetes SD
│   │   ├── configmap.yaml          # Scrape configs for pods (cAdvisor & app /metrics)
│   │   ├── deployment.yaml         # Prometheus Server deployment
│   │   └── service.yaml            # ClusterIP service (:9090)
│   ├── loki/                       # Log aggregation storage engine
│   │   ├── configmap.yaml          # TSDB + Filesystem retention config
│   │   ├── deployment.yaml         # Loki single-binary deployment
│   │   └── service.yaml            # ClusterIP service (:3100)
│   ├── promtail/                   # Node log shipping daemon
│   │   ├── clusterrole.yaml        # RBAC for container & pod metadata
│   │   ├── configmap.yaml          # CRI/JSON parsing & pipeline stages
│   │   └── daemonset.yaml          # DaemonSet mounted to /var/log/pods
│   └── grafana/                    # Central visualization UI
│       ├── configmap-datasources.yaml       # Auto-provisions Prometheus & Loki
│       ├── configmap-dashboards-provider.yaml # Dashboard auto-loader
│       ├── configmap-dashboards.yaml        # Preloaded Microservices & Cluster Dashboards
│       ├── deployment.yaml         # Grafana deployment
│       └── service.yaml            # ClusterIP service (:3000)
│
└── argo-apps/
    ├── root-application.yaml       # Argo CD "App of Apps" root manifest
    ├── dev-apps.yaml               # Application CRDs for database and microservices
    ├── cluster-addons.yaml         # Application for Metrics Server
    └── observability.yaml          # Application for Prometheus, Grafana, Loki & Promtail
```

---

## 🚀 Bootstrapping Argo CD on Amazon EKS

### 1. Install Argo CD into the EKS Cluster
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD components to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

### 2. Access the Argo CD UI
```bash
# Port-forward to your local machine
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```
Open [https://localhost:8080](https://localhost:8080) in your browser (Username: `admin`).

### 3. Deploy the Root App-of-Apps
Ensure `root-application.yaml` points to your GitHub repository URL, then run:

```bash
kubectl apply -f gitops/argo-apps/root-application.yaml
```

Argo CD will automatically detect:
1. `observability-stack` (Wave 0): Creates the `monitoring` namespace and deploys Prometheus, Grafana, Loki, and Promtail.
2. `metrics-server` (Wave 0): Required for Kubernetes HPA autoscaling.
3. `dev-apps` (Waves 1-4): Deploys PostgreSQL, microservices, and the Frontend ingress gateway.

---

## 📊 Accessing Observability Dashboards & Logs

The Observability Stack is pre-configured out-of-the-box with **zero manual setup required** in Grafana:

### 1. Grafana (Visual Metrics & Logs Dashboards)
```bash
kubectl port-forward -n monitoring svc/grafana 3000:3000
```
- **URL**: [http://localhost:3000](http://localhost:3000)
- **Default Credentials**: `admin` / `admin123` (Anonymous Admin access also enabled)
- **Pre-provisioned Data Sources**:
  - `Prometheus` (Default time-series metrics)
  - `Loki` (Centralized structured log explorer)
- **Pre-loaded Dashboards**:
  1. **TaskApp - Microservices Overview**: Real-time HTTP req/sec, 2xx/4xx/5xx status code distribution, 5xx error percentage, active pod counts, and correlated live application logs.
  2. **TaskApp - Cluster Resources & Health**: CPU and Memory consumption per pod, container, and namespace.

### 2. Prometheus (Raw Metrics & Expression Browser)
```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```
- **URL**: [http://localhost:9090](http://localhost:9090)
- **Scrape Targets**: Automatically discovers and scrapes all pods annotated with `prometheus.io/scrape: "true"`, as well as node cAdvisor metrics.

### 3. Loki (Log Querying with LogQL)
```bash
kubectl port-forward -n monitoring svc/loki 3100:3100
```
- In Grafana > **Explore** > Select datasource **Loki**:
  - Search all dev microservice logs:
    ```logql
    {namespace="taskapp-dev"}
    ```
  - Filter for error logs across all services:
    ```logql
    {namespace="taskapp-dev"} |= "error"
    ```
  - Filter user-service logs with duration:
    ```logql
    {namespace="taskapp-dev", pod=~"user-service-.*"} | json
    ```
