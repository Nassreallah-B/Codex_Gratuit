from __future__ import annotations

from dataclasses import dataclass
from typing import Final


@dataclass(frozen=True, slots=True)
class Provider:
    slug: str
    aliases: tuple[str, ...]
    litellm_model: str
    api_base: str | None
    env_key: str
    context_window: int
    supports_reasoning: bool = False
    extra_body: str | None = None
    reasoning_effort: str | None = None


PROVIDERS: Final[tuple[Provider, ...]] = (
    Provider(
        slug="deepseek-flash",
        aliases=("deepseek", "ds", "deepseek-flash"),
        litellm_model="deepseek/deepseek-v4-flash",
        api_base="https://api.deepseek.com",
        env_key="DEEPSEEK_API_KEY",
        context_window=1_048_576,
    ),
    Provider(
        slug="deepseek-pro",
        aliases=("deepseek-pro", "deepseek-v4-pro"),
        litellm_model="deepseek/deepseek-v4-pro",
        api_base="https://api.deepseek.com",
        env_key="DEEPSEEK_API_KEY",
        context_window=1_048_576,
        supports_reasoning=True,
        reasoning_effort="high",
        extra_body='{"thinking": {"type": "enabled"}}',
    ),
    Provider(
        slug="nvidia-deepseek",
        aliases=("nvidia", "nvidia-deepseek", "nv"),
        litellm_model="nvidia_nim/deepseek-ai/deepseek-v4-pro",
        api_base="https://integrate.api.nvidia.com/v1",
        env_key="NVIDIA_API_KEY_DEEPSEEK",
        context_window=1_048_576,
        extra_body='{"chat_template_kwargs": {"thinking": false}}',
    ),
    Provider(
        slug="nvidia-glm",
        aliases=("glm", "nvidia-glm"),
        litellm_model="nvidia_nim/z-ai/glm-5.1",
        api_base="https://integrate.api.nvidia.com/v1",
        env_key="NVIDIA_API_KEY_GLM",
        context_window=200_000,
    ),
    Provider(
        slug="hf",
        aliases=("hf", "huggingface", "qwen"),
        litellm_model="huggingface/Qwen/Qwen3-Coder-Next",
        api_base=None,
        env_key="HF_TOKEN",
        context_window=262_144,
    ),
)


def resolve_provider(value: str) -> Provider:
    normalized = value.strip().lower()
    for provider in PROVIDERS:
        if normalized == provider.slug or normalized in provider.aliases:
            return provider
    valid = ", ".join(provider.slug for provider in PROVIDERS)
    raise ValueError(f"Provider inconnu '{value}'. Providers valides: {valid}")
