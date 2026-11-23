"""Favicon job: an icon fetched from a provider apart from the server, which cannot see the graph, so it gives back what the server keeps."""

import base64;
import urllib.request;

"""The content type and the base64 bytes of what the provider gives at `address`."""
@job
def load_favicon(address: str, note: JobNote) -> list[str];
