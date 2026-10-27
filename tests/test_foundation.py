"""Phase 0 Foundation Verification Tests.

Verifies repository structure, configuration files, agent rules,
and package integrity without external network or cluster dependencies.
"""

import tomllib
from pathlib import Path

import features


def test_required_directories_exist():
    """Verify that all core monorepo directories are present."""
    root = Path(__file__).parent.parent
    expected_dirs = [
        "backend",
        "features",
        "data",
        "training",
        "inference",
        "web",
        "deploy",
        "docs",
        "tests",
        ".github/workflows",
    ]
    for rel_dir in expected_dirs:
        d = root / rel_dir
        assert d.is_dir(), f"Expected directory missing: {rel_dir}"


def test_required_files_exist():
    """Verify that all Phase 0 foundational files exist."""
    root = Path(__file__).parent.parent
    expected_files = [
        "README.md",
        "pyproject.toml",
        "Makefile",
        "run.ps1",
        ".gitignore",
        ".github/workflows/ci.yml",
        "docs/AGENT_RULES.md",
        "docs/STATUS.md",
        "docs/DECISIONS.md",
    ]
    for rel_file in expected_files:
        f = root / rel_file
        assert f.is_file(), f"Expected file missing: {rel_file}"


def test_agent_rules_integrity():
    """Verify that AGENT_RULES.md defines all 16 persistent rules."""
    root = Path(__file__).parent.parent
    rules_file = root / "docs" / "AGENT_RULES.md"
    content = rules_file.read_text(encoding="utf-8")
    for i in range(1, 17):
        assert f"Rule {i}:" in content, f"Rule {i} missing from AGENT_RULES.md"


def test_decisions_contain_core_adrs():
    """Verify that core ADRs are documented in DECISIONS.md."""
    root = Path(__file__).parent.parent
    decisions_file = root / "docs" / "DECISIONS.md"
    content = decisions_file.read_text(encoding="utf-8")
    for adr in [
        "ADR-001",
        "ADR-002",
        "ADR-003",
        "ADR-004",
        "ADR-005",
        "ADR-006",
        "ADR-007",
        "ADR-008",
    ]:
        assert adr in content, f"{adr} missing from DECISIONS.md"


def test_pyproject_toml_validity():
    """Verify that pyproject.toml is valid TOML and specifies aegis project."""
    root = Path(__file__).parent.parent
    pyproject_file = root / "pyproject.toml"
    with open(pyproject_file, "rb") as f:
        data = tomllib.load(f)
    assert data["project"]["name"] == "aegis"
    assert "dependencies" in data["project"]
    assert "tool" in data and "ruff" in data["tool"]
    assert "pytest" in data["tool"]


def test_features_package_import():
    """Verify that the shared features package is importable."""
    assert hasattr(features, "__version__")
    assert features.__version__ == "0.1.0"


def test_phase1_monitoring_files():
    """Verify Phase 1 Milestone 3 monitoring configuration files exist and adhere to constraints."""
    root = Path(__file__).parent.parent
    ns_file = root / "deploy" / "monitoring" / "namespace.yaml"
    values_file = root / "deploy" / "monitoring" / "prometheus-values.yaml"
    deploy_script = root / "deploy" / "scripts" / "deploy-monitoring.ps1"

    assert ns_file.is_file(), "deploy/monitoring/namespace.yaml missing"
    assert values_file.is_file(), "deploy/monitoring/prometheus-values.yaml missing"
    assert deploy_script.is_file(), "deploy/scripts/deploy-monitoring.ps1 missing"

    ns_content = ns_file.read_text(encoding="utf-8")
    assert 'aegis.io/managed: "true"' in ns_content or "aegis.io/managed: 'true'" in ns_content

    values_content = values_file.read_text(encoding="utf-8")
    assert "retention: 3d" in values_content
    assert "memory: 512Mi" in values_content  # Prometheus limit
    assert "memory: 256Mi" in values_content  # Grafana limit
    assert "v92.14.0" in values_content
