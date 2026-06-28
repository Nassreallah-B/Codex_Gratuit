from cloudzir_agent_runtime.cli import main


def test_models_command(capsys):
    assert main(["models"]) == 0
    out = capsys.readouterr().out
    assert "deepseek-flash" in out
    assert "nvidia-glm" in out


def test_codex_dry_run(capsys, tmp_path):
    assert main(["codex", "review", "--provider", "deepseek", "--repo", str(tmp_path), "--dry-run"]) == 0
    out = capsys.readouterr().out
    assert "codex exec" in out
    assert "--sandbox read-only" in out
