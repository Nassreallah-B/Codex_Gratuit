from cloudzir_agent_runtime.deepseek_fix import reorder_tool_calls


def test_reorder_interleaved_assistant_message_after_outputs():
    items = [
        {"type": "function_call", "call_id": "a"},
        {"type": "function_call", "call_id": "b"},
        {"type": "message", "content": "interleaved"},
        {"type": "function_call_output", "call_id": "a"},
        {"type": "function_call_output", "call_id": "b"},
    ]

    assert reorder_tool_calls(items) == [
        {"type": "function_call", "call_id": "a"},
        {"type": "function_call", "call_id": "b"},
        {"type": "function_call_output", "call_id": "a"},
        {"type": "function_call_output", "call_id": "b"},
        {"type": "message", "content": "interleaved"},
    ]


def test_reorder_keeps_regular_messages_stable():
    items = [{"type": "message", "content": "hello"}, {"type": "reasoning"}]
    assert reorder_tool_calls(items) == items


def test_reorder_stops_at_next_call_block_when_outputs_missing():
    items = [
        {"type": "function_call", "call_id": "a"},
        {"type": "message", "content": "deferred"},
        {"type": "function_call", "call_id": "b"},
        {"type": "function_call_output", "call_id": "b"},
    ]
    assert reorder_tool_calls(items) == [
        {"type": "function_call", "call_id": "a"},
        {"type": "message", "content": "deferred"},
        {"type": "function_call", "call_id": "b"},
        {"type": "function_call_output", "call_id": "b"},
    ]
