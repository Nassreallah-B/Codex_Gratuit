from __future__ import annotations

from litellm.integrations.custom_logger import CustomLogger  # type: ignore[import-untyped]

from .deepseek_fix import reorder_tool_calls


class CloudZirCodexToolOrderFix(CustomLogger):
    async def async_pre_call_hook(self, user_api_key_dict, cache, data, call_type):
        try:
            items = data.get("input")
            if isinstance(items, list) and any(item.get("type") == "function_call" for item in items if isinstance(item, dict)):
                data["input"] = reorder_tool_calls(items)
        except Exception:
            pass
        return data


handler = CloudZirCodexToolOrderFix()
