"""Reply: what the REST layer answers with: a status and a JSON body, in the shapes linkding's API uses."""

"""A status and the text of a body; an empty body is sent with no content type."""
obj ApiReply {
    has status: int,
        body: str = "";
}

# WORKAROUND(GAP-033): @restspec answers 200 or 500 only, so the status travels inside the reply and the transport sends it.
"""A reply whose body is the JSON of `value`."""
def reply_json(status: int, value: any) -> ApiReply;

"""A reply of the form {"detail": text}, which linkding uses for every refusal that is not a field error."""
def reply_detail(status: int, detail: str) -> ApiReply;

"""A 400 reply that names each field with its messages."""
def reply_field_errors(errors: dict[str, list[str]]) -> ApiReply;

"""A reply with no body."""
def reply_empty(status: int) -> ApiReply;
