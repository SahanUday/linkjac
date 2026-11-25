"""A local web site the parity checks point both apps at, so no check touches the internet: pages with metadata, a favicon, a redirect, an error."""

import json
import os
import socket
import ssl
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote

PNG = bytes.fromhex("89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4890000000d49444154789c6360000002000001e221bc330000000049454e44ae426082")
PAGES = {
    "/page": b'<html><head><title> Fixture page </title><meta name="description" content="About the fixture"><meta property="og:image" content="/image.png"></head><body><p>Body text</p></body></html>',
    "/og-description": b'<html><head><title>Only og</title><meta property="og:description" content="From og"></head><body></body></html>',
    "/both": b'<html><head><title>Both</title><meta property="og:description" content="Og description"><meta name="description" content="Plain description"><meta property="og:image" content="http://pictures.invalid/pic.png"></head></html>',
    "/no-title": b"<html><head></head><body>nothing here</body></html>",
}
seen = []


class Fixture(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def reply(self, status, kind, body, extra=()):
        self.send_response(status)
        self.send_header("Content-Type", kind)
        self.send_header("Content-Length", str(len(body)))
        for name, value in extra:
            self.send_header(name, value)
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = self.path.split("?")[0]
        if path == "/__seen":
            return self.reply(200, "application/json", json.dumps(seen).encode())
        if path == "/__reset":
            seen.clear()
            return self.reply(200, "text/plain", b"ok")
        seen.append(path)
        if path in PAGES:
            return self.reply(200, "text/html; charset=utf-8", PAGES[path])
        if path == "/gone":
            return self.reply(410, "text/html; charset=utf-8", b"<html><head><title>Gone page</title></head></html>")
        if path.startswith("/guard/"):  # one path for each address a guard check tries, so the check can see which were asked for
            return self.reply(200, "text/html; charset=utf-8", PAGES["/page"])
        if path == "/redirect-to":
            return self.reply(302, "text/plain", b"", [("Location", unquote(self.path.split("url=", 1)[1]))])
        if path == "/redirect":
            return self.reply(302, "text/plain", b"", [("Location", "/page")])
        if path == "/image.png":
            return self.reply(200, "image/png", PNG)
        if path.startswith("/favicon/"):  # a different icon for each domain asked for, so an app that asks for the wrong one shows
            return self.reply(200, "image/png", PNG + path.rsplit("/", 1)[1].encode())
        return self.reply(404, "text/plain", b"not here")


class SixServer(ThreadingHTTPServer):
    address_family = socket.AF_INET6

    def server_bind(self):
        self.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 1)
        super().server_bind()


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 9100
    if os.environ.get("FIXTURE_EVERY_ADDRESS"):  # the guard suite's own network namespace, where private addresses are on the loopback device
        threading.Thread(target=SixServer(("::", port), Fixture).serve_forever, daemon=True).start()
        secure = ThreadingHTTPServer(("0.0.0.0", port + 43), Fixture)
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.load_cert_chain(os.environ["FIXTURE_CERT"], os.environ["FIXTURE_KEY"])
        secure.socket = context.wrap_socket(secure.socket, server_side=True)
        threading.Thread(target=secure.serve_forever, daemon=True).start()
        ThreadingHTTPServer(("0.0.0.0", port), Fixture).serve_forever()
    # The same site on a second loopback address, which an app that allows only 127.0.0.1 must refuse to fetch from.
    threading.Thread(target=ThreadingHTTPServer(("127.0.0.2", port), Fixture).serve_forever, daemon=True).start()
    ThreadingHTTPServer(("127.0.0.1", port), Fixture).serve_forever()
