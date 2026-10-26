# AEGIS Agent Implementation Rules

These persistent rules govern all development, architecture, modeling, data collection, and remediation tasks within the AEGIS project. Every agent and contributor must adhere to them strictly.

---

### Rule 1: Read Source Documents First
Always review the design record (`AEGIS documentation/Aegis_Project_Design_Record.pdf`), `docs/AGENT_RULES.md`, and `docs/STATUS.md` before starting any task. Later decisions and corrections in the design record override earlier proposals.

### Rule 2: Plan Before Substantial Changes
Never make breaking or architectural modifications without first producing an explicit, step-by-step plan and waiting for user review/approval.

### Rule 3: Absolute Scientific Honesty
Never invent or fabricate benchmark scores, test results, run counts, latency numbers, screenshots, or simulation outcomes. If an experiment fails or underperforms, report the honest measurements.

### Rule 4: Mark Unverified Work Truthfully
Mark any simulated, mock, or incomplete functionality explicitly as `TODO` or `NOT VERIFIED`. Never present placeholder implementations as complete production logic.

### Rule 5: Establish the Baseline Ladder
Establish and evaluate simple baselines before training or shipping complex ML models:
* Metric forecasting: Static threshold alert and linear trend extrapolation (`predict_linear`).
* Log anomaly detection: Count-vector PCA / Isolation Forest baseline.
* Root-cause analysis: Topology heuristic / Personalized PageRank baseline.
* Remediation: Static rules playbook.
An advanced model ships only if it outperforms the baseline on held-out runs.

### Rule 6: Split by Run, Never by Row
Always partition datasets by complete chaos experiment run, never by randomly shuffling time-series rows or windows. Keep the final held-out test set locked until formal evaluation to prevent data leakage.

### Rule 7: Shared Feature Library
Use the single, shared `features/` library for both offline training and online real-time inference to strictly avoid train/serve skew.

### Rule 8: Strict LLM Separation
The LLM copilot is an explanatory and summarization layer grounded in runbooks via RAG. It must **never** be on the execution path and must **never** choose or execute Kubernetes actions.

### Rule 9: Human-in-the-Loop Remediation
Autonomous remediation (L3) is disabled in V1. All actions require explicit, fresh, single-use human approval (L2 Approve-to-act) bound to a dry-run plan hash with an expiration window.

### Rule 10: Cluster Isolation & Sandbox Defense
Never connect to, read from, or write to any non-sandbox or production cluster. Verify the active Kubernetes context, cluster ID, and namespace (`boutique`) before any cluster interaction.

### Rule 11: Web API Privilege Separation
The web frontend and general API service (`aegis-api`) must have zero direct Kubernetes write permissions. Only the dedicated in-cluster `aegis-executor` ServiceAccount may execute allow-listed patches.

### Rule 12: Minimal Architecture in V1
Do not introduce unnecessary distributed infrastructure into V1. No Kafka, Redis, Feast, Airflow, or KServe unless explicitly justified and approved. Use PostgreSQL + `pgvector` with `LISTEN/NOTIFY` as the central hub.

### Rule 13: Verifiable Evidence
Every completed milestone or task must be backed by verifiable evidence: real test results, actual command outputs, and reproducible scripts.

### Rule 14: Continuous Status Updates
Update `docs/STATUS.md` after every completed milestone with exact changes, verification proof, open issues, and next steps.

### Rule 15: No Unverified Completion Claims
Never declare a phase or milestone complete until all defined acceptance criteria have been verified against running systems or passing test suites.

### Rule 16: Zero Secrets in Version Control
Never commit passwords, tokens, API keys, private certificates, or sensitive credentials to Git. Use environment variables and `.gitignore` exclusions.
