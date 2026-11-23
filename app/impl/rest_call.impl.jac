import json;
import from urllib.parse { parse_qsl }

impl make_call(method: str, path: str, query: str, body: str, origin: str) -> ApiCall {
    segments = [s for s in path.split("/") if s];
    values: dict[str, str] = {};
    for (name, value) in parse_qsl(query, keep_blank_values=True) {
        values[name] = value;
    }
    return ApiCall(method=method, segments=segments[1:], query=values, body=body, origin=origin);
}

impl query_value(call: ApiCall, name: str, fallback: str = "") -> str {
    return call.query.get(name, fallback);
}

impl body_object(call: ApiCall) -> dict[str, any] | None {
    try {
        parsed = json.loads(call.body);
    } except ValueError {
        return None;
    }
    if isinstance(parsed, dict) {
        return parsed;
    }
    return None;
}

impl id_in_path(text: str) -> int {
    return int(text) if text.isascii() and text.isdigit() and len(text) <= 18 else 0;
}
