from __future__ import annotations

import argparse
import shutil
import socket
import subprocess
import sys
from pathlib import Path

from .config import ensure_env_file, ensure_runtime_dirs, merged_env, paths
from .litellm_config import render_litellm_config
from .providers import PROVIDERS, resolve_provider


def _port_open(port: int, host: str = "127.0.0.1", timeout: float = 0.25) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(timeout)
        return sock.connect_ex((host, port)) == 0


def cmd_init(args: argparse.Namespace) -> int:
    runtime_paths = paths(Path(args.home) if args.home else None)
    ensure_runtime_dirs(runtime_paths)
    ensure_env_file(runtime_paths)
    provider = resolve_provider(args.provider)
    runtime_paths.config_yaml.write_text(render_litellm_config(provider), encoding="utf-8")
    print(f"Runtime initialise: {runtime_paths.root}")
    print(f"Config LiteLLM: {runtime_paths.config_yaml}")
    print(f"Secrets: {runtime_paths.env_file}")
    return 0


def cmd_generate_config(args: argparse.Namespace) -> int:
    provider = resolve_provider(args.provider)
    content = render_litellm_config(provider)
    if args.output:
        output = Path(args.output).expanduser().resolve()
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(content, encoding="utf-8")
        print(output)
    else:
        print(content)
    return 0


def cmd_models(_: argparse.Namespace) -> int:
    for provider in PROVIDERS:
        aliases = ", ".join(provider.aliases)
        print(f"{provider.slug}\t{provider.litellm_model}\tctx={provider.context_window}\taliases={aliases}")
    return 0


def cmd_doctor(args: argparse.Namespace) -> int:
    runtime_paths = paths(Path(args.home) if args.home else None)
    env = merged_env(runtime_paths)
    checks: list[tuple[str, bool, str]] = []
    checks.append(("python>=3.10", sys.version_info >= (3, 10), sys.version.split()[0]))
    checks.append(("codex CLI", shutil.which("codex") is not None, shutil.which("codex") or "missing"))
    checks.append(("litellm CLI", shutil.which("litellm") is not None, shutil.which("litellm") or "missing"))
    checks.append(("runtime home", runtime_paths.root.exists(), str(runtime_paths.root)))
    checks.append((".env", runtime_paths.env_file.exists(), str(runtime_paths.env_file)))
    checks.append(("config.yaml", runtime_paths.config_yaml.exists(), str(runtime_paths.config_yaml)))
    checks.append(("port 4000", _port_open(args.port), "open" if _port_open(args.port) else "closed"))
    for provider in PROVIDERS:
        checks.append((provider.env_key, bool(env.get(provider.env_key)), "set" if env.get(provider.env_key) else "empty"))

    ok = True
    for name, passed, detail in checks:
        icon = "OK" if passed else "WARN"
        if name in {"python>=3.10"} and not passed:
            ok = False
            icon = "FAIL"
        print(f"[{icon}] {name}: {detail}")
    return 0 if ok else 1


def cmd_start_proxy(args: argparse.Namespace) -> int:
    runtime_paths = paths(Path(args.home) if args.home else None)
    ensure_runtime_dirs(runtime_paths)
    ensure_env_file(runtime_paths)
    provider = resolve_provider(args.provider)
    runtime_paths.config_yaml.write_text(render_litellm_config(provider), encoding="utf-8")
    env = merged_env(runtime_paths)
    cmd = ["litellm", "--config", str(runtime_paths.config_yaml), "--port", str(args.port)]
    print(" ".join(cmd))
    return subprocess.call(cmd, cwd=runtime_paths.litellm_dir, env=env)


def _review_prompt(mode: str, base: str | None) -> str:
    target = (
        f"Compare la branche a la reference '{base}' : `git diff {base}...HEAD` (+ `git log --oneline {base}..HEAD`)."
        if base
        else "Relis le travail NON COMMITE : `git status --short --untracked-files=all`, puis `git diff` et `git diff --cached`, et lis les fichiers non suivis."
    )
    if mode == "critique":
        return (
            "Tu es un relecteur de code ADVERSARIAL red-team. Cherche le pire bug cache, en lecture seule.\n"
            f"{target}\n"
            "Rends findings par gravite avec fichier:ligne, repro concret, impact, correctif et verdict."
        )
    return (
        "Tu es un relecteur de code senior. Fais une revue rigoureuse, en lecture seule.\n"
        f"{target}\n"
        "Rends resume, findings [CRITIQUE|ELEVEE|MOYENNE|FAIBLE] avec correctif, puis recommandation finale."
    )


def cmd_codex(args: argparse.Namespace) -> int:
    provider = resolve_provider(args.provider)
    sandbox = "workspace-write" if args.write else "read-only"
    if args.mode in {"review", "critique"}:
        prompt = _review_prompt(args.mode, args.base)
    else:
        if not args.prompt:
            print("--prompt est requis en mode task", file=sys.stderr)
            return 2
        prompt = args.prompt
    cmd = [
        "codex",
        "exec",
        "-c",
        "model_provider=litellm",
        "-m",
        provider.slug,
        "--sandbox",
        sandbox,
        "--skip-git-repo-check",
        "--color",
        "never",
        "-C",
        str(Path(args.repo).resolve()),
        prompt,
    ]
    if args.dry_run:
        print(" ".join(cmd))
        return 0
    return subprocess.call(cmd)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="cloudzir-agent", description="Runtime CloudZIR multi-provider pour Codex + LiteLLM")
    sub = parser.add_subparsers(dest="command", required=True)

    init = sub.add_parser("init", help="Initialise le runtime local")
    init.add_argument("--home")
    init.add_argument("--provider", default="deepseek-flash")
    init.set_defaults(func=cmd_init)

    gen = sub.add_parser("generate-config", help="Genere config.yaml LiteLLM")
    gen.add_argument("--provider", default="deepseek-flash")
    gen.add_argument("--output")
    gen.set_defaults(func=cmd_generate_config)

    models = sub.add_parser("models", help="Liste les providers supportes")
    models.set_defaults(func=cmd_models)

    doctor = sub.add_parser("doctor", help="Verifie l'environnement local")
    doctor.add_argument("--home")
    doctor.add_argument("--port", type=int, default=4000)
    doctor.set_defaults(func=cmd_doctor)

    start = sub.add_parser("start-proxy", help="Lance LiteLLM avec config generee")
    start.add_argument("--home")
    start.add_argument("--provider", default="deepseek-flash")
    start.add_argument("--port", type=int, default=4000)
    start.set_defaults(func=cmd_start_proxy)

    codex = sub.add_parser("codex", help="Lance codex exec via provider LiteLLM")
    codex.add_argument("mode", choices=("review", "critique", "task"))
    codex.add_argument("--provider", default="deepseek-flash")
    codex.add_argument("--base")
    codex.add_argument("--prompt")
    codex.add_argument("--repo", default=".")
    codex.add_argument("--write", action="store_true")
    codex.add_argument("--dry-run", action="store_true")
    codex.set_defaults(func=cmd_codex)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        return int(args.func(args))
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
