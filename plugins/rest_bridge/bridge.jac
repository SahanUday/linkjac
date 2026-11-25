"""Rest bridge: a transport that serves HTTP and hands every request under one path prefix to the app as a single call."""

import json;
import base64;
import threading;
import from http.client { HTTPConnection }
import from urllib.parse { urlsplit }
import from http.server { BaseHTTPRequestHandler, ThreadingHTTPServer }
import from common.contract { Host }
import from token_header.words { token_words }
import from transport.contract { Transport, Request, Response, Tick, Claim, CannotListen }

"""What the running listener needs while it answers: the settings and the app's own handler."""
glob prefix_now: str = "/api/",
     call_now: str = "",
     public_call_now: str = "",
     static_now: str = "",
     handler_now: Callable[[Request], Response] | None = None;

"""The listening socket this transport took for the program."""
obj Door(Claim) {
    has server: ThreadingHTTPServer;
}

"""One request from a client, passed on and answered."""
class Gateway(BaseHTTPRequestHandler) {
    def relay(method: str);

    def do_GET;

    def do_POST;

    def do_PUT;

    def do_PATCH;

    def do_DELETE;

    override def log_message(format: str, *args: any);
}

"""Whether nothing of the app takes this request: not a GET, and neither under the API nor one of the runtime's own paths."""
def takes_nothing(sent: Request, api_prefix: str) -> bool;

"""The app's own handler for a request."""
def answer(sent: Request) -> Response;

"""What linkding says of a `Token` or `Bearer` header that has no key or has spaces in it, or "" for any other header."""
def header_fault(header: str) -> str;

"""The request for the app's one REST endpoint that stands for `sent`: the guarded one when it carries a token, else the public one."""
def rest_call_for(sent: Request) -> Request;

"""The reply a client of the REST API sees for what the app's REST endpoint answered; a refused token is linkding's "Invalid token."; a file (`__file__` in the body: content type, base64 bytes, a name) is sent as its bytes."""
def rest_reply_from(inner: Response) -> Response;

# WORKAROUND(GAP-037): the standard transport cannot be extended, so this one stands in for it (no streams, limits or keep-alive).
# WORKAROUND(GAP-030): @restspec serves GET and POST only, so this transport carries every method.
# WORKAROUND(GAP-031): @restspec paths are exact, so every path under the prefix goes to one endpoint.
# WORKAROUND(GAP-032): a @restspec function cannot read the request, so the transport passes query, body and origin as arguments.
# WORKAROUND(GAP-033): @restspec answers 200 or 500 only, so the endpoint returns the status and the transport sends it.
"""Serves HTTP with the standard library and sends requests under `api_prefix` to `call_path`."""
obj RestBridge(Transport) {
    """The path prefix whose requests become one call of the app: `call_path` is the endpoint for a request with credentials, `public_call_path` for one without."""
    has api_prefix: str = "/api/",
        call_path: str = "",
        public_call_path: str = "",
        static_prefix: str = "";

    def open(host: dyn Host);

    def send(address: str, r: Request, seconds: float) -> Response;

    def claim(address: str) -> Claim;

    def listen(
        claim: Claim,
        handle: Callable[[Request], Response],
        ticks: list[Tick],
        listening: Callable[[int], None] | None,
    );

    def on_loop(work: Callable[[], None]);

    def serving -> bool;

    def serves_paths -> bool;
}
