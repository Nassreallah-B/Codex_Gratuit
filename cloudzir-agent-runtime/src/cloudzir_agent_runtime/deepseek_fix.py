from __future__ import annotations

from collections.abc import Iterable
from typing import Any


def _item_type(item: Any) -> str | None:
    if isinstance(item, dict):
        value = item.get("type")
        return value if isinstance(value, str) else None
    value = getattr(item, "type", None)
    return value if isinstance(value, str) else None


def _call_id(item: Any) -> str | None:
    if isinstance(item, dict):
        value = item.get("call_id")
        return value if isinstance(value, str) else None
    value = getattr(item, "call_id", None)
    return value if isinstance(value, str) else None


def reorder_tool_calls(items: Iterable[Any]) -> list[Any]:
    """Place tool outputs immediately after their tool call block.

    Codex Responses payloads may contain interleaved assistant messages between
    parallel function calls and their outputs. Strict chat providers reject this
    sequence. This function is stable: it keeps relative order inside call,
    output and deferred message groups, and never drops items.
    """
    source = list(items)
    result: list[Any] = []
    index = 0
    total = len(source)

    while index < total:
        if _item_type(source[index]) != "function_call":
            result.append(source[index])
            index += 1
            continue

        calls: list[Any] = []
        while index < total and _item_type(source[index]) == "function_call":
            calls.append(source[index])
            index += 1

        expected = {call_id for call_id in (_call_id(item) for item in calls) if call_id}
        outputs: list[Any] = []
        deferred: list[Any] = []
        received: set[str] = set()

        while index < total and (not expected or received != expected):
            item = source[index]
            item_type = _item_type(item)
            if item_type == "function_call_output":
                outputs.append(item)
                call_id = _call_id(item)
                if call_id:
                    received.add(call_id)
                index += 1
            elif item_type == "function_call":
                break
            else:
                deferred.append(item)
                index += 1

        result.extend(calls)
        result.extend(outputs)
        result.extend(deferred)

    return result
