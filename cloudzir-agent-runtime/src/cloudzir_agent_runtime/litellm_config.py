from __future__ import annotations

from .providers import PROVIDERS, Provider


def _provider_block(provider: Provider, name: str | None = None) -> str:
    model_name = name or provider.slug
    lines = [
        f"  - model_name: {model_name}",
        "    litellm_params:",
        f"      model: {provider.litellm_model}",
    ]
    if provider.api_base:
        lines.append(f"      api_base: {provider.api_base}")
    lines.extend(
        [
            f"      api_key: os.environ/{provider.env_key}",
            "      use_chat_completions_api: true",
        ]
    )
    if provider.reasoning_effort:
        lines.append(f"      reasoning_effort: {provider.reasoning_effort}")
    if provider.extra_body:
        lines.append(f"      extra_body: {provider.extra_body}")
    lines.extend(
        [
            "    model_info:",
            f"      context_window: {provider.context_window}",
            f"      max_context_window: {provider.context_window}",
        ]
    )
    return "\n".join(lines)


def render_litellm_config(default_provider: Provider, master_key_env: str = "LITELLM_MASTER_KEY") -> str:
    blocks = [_provider_block(provider) for provider in PROVIDERS]
    blocks.append(_provider_block(default_provider, name='"*"'))
    return (
        "# CloudZIR Agent Runtime — generated file. Do not edit manually.\n"
        "model_list:\n"
        + "\n\n".join(blocks)
        + "\n\nlitellm_settings:\n"
        "  drop_params: true\n"
        "  callbacks: cloudzir_agent_runtime.litellm_callback.handler\n\n"
        "general_settings:\n"
        f"  master_key: os.environ/{master_key_env}\n"
    )
