# AEGIS: AI-Powered Autonomous SRE for Kubernetes

**AEGIS** (Autonomous Engine for Guarding Infrastructure Systems) is an intelligent site reliability engineering system that observes a running Kubernetes microservices application, predicts failures before they cause user impact, pinpoints the root-cause service, recommends verified remediations, and—with human approval—safely executes and verifies the fix.

---

## High-Level Architecture

```text
    ┌────────────────────────────────────────────────────────┐
    │              React Dashboard (Primary UI)              │
    │      Risk Heatmap | Live Charts | Replay (10x)         │
    └───────────────▲────────────────────────┬───────────────┘
                    │ REST / SSE             │ Approvals
    ┌───────────────┴──────────────┐         │
    │      aegis-api (FastAPI)     │         │
    └───────────────▲──────────────┘         ▼
                    │               ┌────────────────────────┐
                    │               │     aegis-executor     │
                    │               │ (Only cluster writer)  │
                    │               └────────────┬───────────┘
    ┌───────────────┴──────────────┐             │
    │     PostgreSQL + pgvector    │             │ Validated patches
    │   Shared state & event bus   │             │ (Bounded by RBAC
    └───────────────▲──────────────┘             │  & Admission Policy)
                    │                            │
    ┌───────────────┴──────────────┐             ▼
    │      aegis-engine (15s)      │      ┌──────────────┐
    │  Telemetry -> Features       │      │  Kubernetes  │
    └───────▲──────────────▲───────┘      │   Cluster    │
            │              │              │   (kind)     │
    ┌───────┴──────┐ ┌─────┴──────┐       │              │
    │  Prometheus  │ │    Loki    │       │   Boutique   │
    │  (cAdvisor,  │ │  (Grafana  │◄──────┤ Microservices│
    │  OTel Spans) │ │   Alloy)   │       └──────────────┘
    └──────────────┘ └────────────┘
```

---

## Core Engineering Principles

1. **Not an LLM Wrapper**: Fast, deterministic ML models handle detection, forecasting, and ranking in milliseconds. The LLM (via Ollama/RAG) strictly explains findings and retrieves runbook guidance—it never selects or executes Kubernetes actions.
2. **Honest Baseline Ladder**: Advanced models (e.g., sequence models or graph networks) only ship if they measurably beat standard baselines (Prometheus `predict_linear`, static thresholds, Isolation Forest, rules-based playbooks) on held-out runs.
3. **Run-Level Splitting**: Zero temporal data leakage. Datasets are partitioned strictly by complete chaos experiment runs, never by shuffling sliding windows.
4. **Defense-in-Depth Remediation**: The AI proposes, a human approves, and Kubernetes enforces. Actions are restricted to a strict 4-operation whitelist with cryptographic plan hashing, expiry, and cluster-side CEL admission policies.
5. **Fast 90-Second Demo**: Built-in 10x replay mode allows interviewers to witness a complete 10-minute failure, diagnosis, and automated recovery cycle in under 60 seconds without risking flaky live demos.

---

## Monorepo Directory Structure

```text
AEGIS/
├── backend/          # aegis-api (REST/SSE), aegis-engine (15s loop), executor, copilot
├── features/         # Shared feature engineering library (prevents train/serve skew)
├── data/             # Run registry, experiment runners, Parquet export pipelines
├── training/         # Baseline and advanced models, MLflow configs, evaluation harness
├── inference/        # Model inference microservice (/v1/score, /v1/rca, /v1/recommend)
├── web/              # React + TypeScript + Vite dashboard (primary interface)
├── deploy/           # kind cluster configs, Helm charts, admission policies, chaos manifests
├── docs/             # Agent rules, status tracking, architecture decision records
├── tests/            # Test suite (unit, integration, safety verification)
├── Makefile          # POSIX task runner for CI and Linux/WSL
├── run.ps1           # Native Windows PowerShell task runner
└── pyproject.toml    # Python project configuration (Ruff & pytest)
```

---

## Prerequisites

* **Operating System**: Windows 11, Linux, or macOS
* **Runtimes**: Python 3.11+, Node.js 20+, Docker Desktop (WSL2 backend on Windows)
* **Kubernetes Tools**: `kind` (v0.20+), `kubectl` (v1.28+)

---

## Developer Quickstart

### Windows PowerShell
```powershell
# Display available tasks
.\run.ps1 help

# Run code linting (Ruff)
.\run.ps1 lint

# Run unit tests (pytest)
.\run.ps1 test
```

### Linux / macOS / WSL / CI
```bash
# Display available tasks
make help

# Run linter and tests
make lint
make test
```

---

## Current Status

See [`docs/STATUS.md`](docs/STATUS.md) for the active phase, completed milestones, real verification outputs, and immediate next steps. Persistent guidelines are defined in [`docs/AGENT_RULES.md`](docs/AGENT_RULES.md).
>>>>>>> f4faa48 (feat(core): initialize AEGIS Phase 0 repository foundation)
