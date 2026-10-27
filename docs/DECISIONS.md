# AEGIS Architecture Decision Records (ADRs)

This document records the foundational architectural decisions for AEGIS, their context, and their rationale as agreed upon in the project design record.

---

### ADR-001: PostgreSQL + pgvector as Hub and Event Bus (No Redis or Kafka in V1)
* **Status**: Accepted
* **Context**: The engine, API, and executor need shared state (incidents, timelines, approvals, audit logs, runbook embeddings) and real-time event broadcasting.
* **Decision**: Use a single PostgreSQL database with the `pgvector` extension and PostgreSQL `LISTEN/NOTIFY` for pub/sub.
* **Rationale**:
  * With 11 microservices polled every 15 seconds, telemetry ingestion rate is lightweight. Introducing Kafka adds significant operational overhead without throughput benefit.
  * `LISTEN/NOTIFY` supports real-time event fan-out to API replicas and SSE clients without requiring a Redis daemon.
  * Storing runbook vectors directly in `pgvector` eliminates the operational overhead of running a separate vector database (like Milvus or Qdrant).

---

### ADR-002: Local Kubernetes Environment via `kind`
* **Status**: Accepted
* **Context**: Need a fast, reproducible multi-node cluster that runs locally on a 16 GB laptop and integrates with CI (GitHub Actions).
* **Decision**: Use `kind` (Kubernetes in Docker) with 1 control-plane and 2 worker nodes (or 1 worker in constrained memory).
* **Rationale**:
  * Disposable and quick to tear down / recreate across 100+ experimental runs.
  * Native multi-node topology allows testing real network latency and node-level failure propagation.
  * Works identically in local development and in GitHub Actions CI.

---

### ADR-003: Log Shipping via Grafana Alloy (Promtail EOL) & Minimal OpenTelemetry
* **Status**: Accepted
* **Context**:
  * Promtail reached official End-of-Life (EOL) in March 2026; Grafana unified collector capabilities into Grafana Alloy.
  * Online Boutique does not natively export per-service latency and error rate metrics to Prometheus.
* **Decision**:
  * Deploy Grafana Alloy to ship container logs to Grafana Loki.
  * Deploy OpenTelemetry Collector utilizing the `spanmetrics` connector to derive per-service request rate, error rate, and p95 latency for Prometheus scraping. Full trace storage (Tempo/Jaeger) is deferred to V2.

---

### ADR-004: React Dashboard as the Primary User Interface
* **Status**: Accepted
* **Context**: First impressions matter for recruiters, technical interviewers, and SRE demonstrations. Terminal CLI alone fails to convey multi-service failure propagation visually.
* **Decision**: Build a modern web dashboard using React + TypeScript + Vite + Tailwind CSS + shadcn/ui + Recharts + React Flow as the primary interface. Provide a lightweight CLI as secondary.
* **Rationale**:
  * Supports rich visualization: real-time risk heatmaps, interactive service dependency graphs, live metric comparisons (forecast vs 85% threshold alerts), and 10x scenario replay controls.
  * Decoupled frontend consuming clean OpenAPI REST and Server-Sent Events (SSE) endpoints.

---

### ADR-005: V1 Model Scope and the Baseline Ladder
* **Status**: Accepted
* **Context**: Ambitious research models (e.g., Graph Neural Networks and PPO Reinforcement Learning) have high training complexity, require large datasets, and risk delaying the project.
* **Decision**:
  * **Failure Forecaster**: Baselines (Static threshold, linear trend extrapolation via `predict_linear`, XGBoost) vs. Advanced (LSTM/GRU). Advanced only ships if it beats baselines on held-out runs.
  * **Log Anomaly**: Baseline (Count-vector PCA / Isolation Forest) vs. Advanced (DeepLog LSTM on normal sequences).
  * **Root Cause Analysis (RCA)**: Personalized PageRank over reversed dependency graph in V1. GNN (GraphSAGE) deferred to V2.
  * **Remediation Recommender**: Supervised classifier / empirical lookup table trained on randomized intervention runs in V1. Gymnasium + PPO deferred to V2.

---

### ADR-006: Safe Remediation Pipeline & Defense-in-Depth
* **Status**: Accepted
* **Context**: An AI system that modifies infrastructure must never cause accidental outages, execute prompt injections, or damage cluster state.
* **Decision**: Enforce three independent defensive walls:
  1. **Strict Action Whitelist**: Only 4 safe actions allowed (`rollback_deployment`, `restart_deployment`, `scale_deployment` bounded +1/+2, `no_op`). Zero support for delete verbs, pod exec, or arbitrary YAML.
  2. **Plan-Hash Human Approval**: Remediation proposals generate a dry-run diff with a SHA256 plan hash and 10-minute expiry. Executor re-verifies live resource version and health preconditions before applying.
  3. **Cluster Admission Policy**: ValidatingAdmissionPolicy (CEL) or Kyverno enforcing that even a compromised executor identity cannot modify fields outside replica count, restart annotation, or previously known image tags.

---

### ADR-007: Data Integrity and Leakage Prevention
* **Status**: Accepted
* **Context**: Time-series models frequently suffer from severe data leakage if split naively by row or sliding window.
* **Decision**:
  * **Split by run, never by row**: All training, validation, and test splits are partitioned by complete chaos experiment runs.
  * **Benign deployments**: Normal runs must include benign deployments at random intervals to prevent models from learning "recent deploy = failure".
  * **Locked test set**: Final evaluation runs are held out and evaluated only once at project completion.

---

### ADR-008: Lightweight Prometheus & Grafana Stack with Strict Memory Bounding
* **Status**: Accepted
* **Context**: Monitoring a 12-microservice Kubernetes cluster locally on a 16 GB laptop host requires full metric scraping (cAdvisor, kube-state-metrics, node-exporter) without exhausting Docker or host memory.
* **Decision**: Deploy `prometheus-community/kube-prometheus-stack` pinned to `v92.14.0` in the `monitoring` namespace with strict resource limits:
  * **Prometheus**: Memory limit $\le 512\text{ MiB}$ (requests $256\text{ MiB}$), CPU limit $500\text{m}$ (requests $100\text{m}$), retention strictly set to $3\text{ days}$ ($4\text{ GiB}$ max), backed by a $5\text{ GiB}$ PVC (`standard` local-path storage class).
  * **Grafana**: Memory limit $\le 256\text{ MiB}$ (requests $128\text{ MiB}$), CPU limit $200\text{m}$ (requests $50\text{m}$). Disabled memory-heavy dashboard/datasource sidecars (provisioned declaratively via ConfigMap), disabled unified alerting engine, and tuned Go runtime (`GOMEMLIMIT=210MiB`, `GOGC=50`).
  * **Alertmanager & Default Rules**: Alertmanager and heavy alerting evaluation rules are disabled in Milestone 3 to conserve CPU and RAM.
  * **Local-Only Access**: Services expose ClusterIP only; access is via authenticated local `kubectl port-forward` commands.

