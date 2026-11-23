"""Rest bridge: a transport that serves HTTP and hands every request under one path prefix to the app as a single call."""

import json;
import threading;
import from http.server { BaseHTTPRequestHandler, ThreadingHTTPServer }
import from common.contract { Host }
import from transport.contract { Transport, Request, Response, Tick, Claim, CannotListen }

"""What the running listener needs while it answers: the settings and the app's own handler."""
glob prefix_now: str = "/api/",
     call_now: str = "",
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

"""The app's own handler for a request."""
def answer(sent: Request) -> Response;

"""The request for the app's one REST endpoint that stands for `sent`, with `Token` keyword turned into `Bearer`."""
def rest_call_for(sent: Request) -> Request;

"""The reply a client of the REST API sees for what the app's REST endpoint answered."""
def rest_reply_from(inner: Response, had_credentials: bool) -> Response;

"""Serves HTTP with the standard library and sends requests under `api_prefix` to `call_path`."""
obj RestBridge(Transport) {
    """The path prefix whose requests become one call of the app."""
    has api_prefix: str = "/api/",
        call_path: str = "";

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
