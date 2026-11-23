"""Tests for how the bridge reads what the app's REST endpoint answered."""

import json;
import from transport.contract { Response }

def app_answer(status: int, body: str) -> Response {
    return Response(
        status=status, ctype="application/json", body=body.encode("utf-8"), headers={}, events=None
    );
}

test "an answer that is not JSON becomes a 500 that says so" {
    reply = rest_reply_from(app_answer(200, "<html>oops</html>"));
    assert reply.status == 500;
    assert "does not know" in json.loads(reply.body.decode("utf-8"))["detail"];
}

test "JSON without the envelope's keys becomes a 500 that says so" {
    reply = rest_reply_from(app_answer(200, "{\"something\": 1}"));
    assert reply.status == 500;
    reply = rest_reply_from(app_answer(200, "[1, 2]"));
    assert reply.status == 500;
}

test "an envelope whose data is not a status and a body becomes a 500" {
    reply = rest_reply_from(app_answer(200, "{\"ok\": true, \"data\": 5}"));
    assert reply.status == 500;
}

test "a good envelope passes its status and body through" {
    inner = app_answer(
        200, json.dumps({"ok": True, "data": {"status": 201, "body": "{\"id\": 1}"}})
    );
    reply = rest_reply_from(inner);
    assert reply.status == 201;
    assert reply.body.decode("utf-8") == "{\"id\": 1}";
}

test "a 401 from the app is linkding's invalid-token answer" {
    reply = rest_reply_from(app_answer(401, "{}"));
    assert reply.status == 401;
    assert json.loads(reply.body.decode("utf-8")) == {"detail": "Invalid token."};
}
