from __future__ import annotations

import os
import secrets
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True, slots=True)
class RuntimePaths:
    root: Path
    litellm_dir: Path
    config_yaml: Path
    env_file: Path
    reports_dir: Path


def default_root() -> Path:
    override = os.environ.get("CLOUDZIR_AGENT_HOME")
    if override:
        return Path(override).expanduser().resolve()
    return (Path.home() / ".cloudzir-agent-runtime").resolve()


def paths(root: Path | None = None) -> RuntimePaths:
    base = (root or default_root()).expanduser().resolve()
    litellm = base / "litellm"
    return RuntimePaths(
        root=base,
        litellm_dir=litellm,
        config_yaml=litellm / "config.yaml",
        env_file=base / ".env",
        reports_dir=base / "reports",
    )


def ensure_runtime_dirs(runtime_paths: RuntimePaths) -> None:
    runtime_paths.root.mkdir(parents=True, exist_ok=True)
    runtime_paths.litellm_dir.mkdir(parents=True, exist_ok=True)
    runtime_paths.reports_dir.mkdir(parents=True, exist_ok=True)


def ensure_env_file(runtime_paths: RuntimePaths) -> None:
    if runtime_paths.env_file.exists():
        return
    token = "sk-cz-" + secrets.token_urlsafe(32)
    runtime_paths.env_file.write_text(
        "# CloudZIR Agent Runtime secrets\n"
        "# Remplis uniquement les providers que tu utilises.\n"
        f"LITELLM_MASTER_KEY={token}\n"
        "DEEPSEEK_API_KEY=\n"
        "NVIDIA_API_KEY_DEEPSEEK=\n"
        "NVIDIA_API_KEY_GLM=\n"
        "HF_TOKEN=\n",
        encoding="utf-8",
    )


def load_env_file(env_file: Path) -> dict[str, str]:
    if not env_file.exists():
        return {}
    values: dict[str, str] = {}
    for raw_line in env_file.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key:
            values[key] = value
    return values


def merged_env(runtime_paths: RuntimePaths) -> dict[str, str]:
    values = load_env_file(runtime_paths.env_file)
    merged = dict(os.environ)
    for key, value in values.items():
        if value:
            merged[key] = value
    return merged
