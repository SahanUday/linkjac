import json;

impl reply_json(status: int, value: any) -> ApiReply {
    return ApiReply(status=status, body=json.dumps(value));
}

impl reply_detail(status: int, detail: str) -> ApiReply {
    return reply_json(status, {"detail": detail});
}

impl reply_field_errors(errors: dict[str, list[str]]) -> ApiReply {
    return reply_json(400, errors);
}

impl reply_empty(status: int) -> ApiReply {
    return ApiReply(status=status);
}
