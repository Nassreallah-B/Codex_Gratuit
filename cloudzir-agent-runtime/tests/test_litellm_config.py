from cloudzir_agent_runtime.litellm_config import render_litellm_config
from cloudzir_agent_runtime.providers import resolve_provider


def test_render_config_contains_wildcard_and_master_key_env():
    config = render_litellm_config(resolve_provider("deepseek"))
    assert 'model_name: "*"' in config
    assert "master_key: os.environ/LITELLM_MASTER_KEY" in config
    assert "callbacks: cloudzir_agent_runtime.litellm_callback.handler" in config


def test_resolve_provider_aliases():
    assert resolve_provider("ds").slug == "deepseek-flash"
    assert resolve_provider("glm").slug == "nvidia-glm"


def test_context_windows_match_provider_capabilities():
    assert resolve_provider("deepseek").context_window == 1_048_576
    assert resolve_provider("nvidia").context_window == 1_048_576
    assert resolve_provider("glm").context_window == 200_000
    assert resolve_provider("hf").context_window == 262_144
