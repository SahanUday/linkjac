import json;

impl reply_json(status: int, value: any) -> ApiReply {
    return ApiReply(status=status, body=json.dumps(value));
}

impl reply_detail(status: int, detail: str) -> ApiReply {
    return reply_json(status, {"detail": detail});
}

impl reply_not_found -> ApiReply {
    return reply_detail(404, "Not found.");
}

impl reply_field_errors(errors: dict[str, list[str]]) -> ApiReply {
    return reply_json(400, errors);
}

impl reply_not_allowed(method: str) -> ApiReply {
    return reply_detail(405, f"Method \"{method}\" not allowed.");
}

impl reply_not_a_dictionary -> ApiReply {
    return reply_field_errors({"non_field_errors": ["Invalid data. Expected a dictionary."]});
}

impl reply_file(content_type: str, data: str, filename: str) -> ApiReply {
    return reply_json(200, {"__file__": {"type": content_type, "base64": data, "name": filename}});
}

impl reply_empty(status: int) -> ApiReply {
    return ApiReply(status=status);
}
