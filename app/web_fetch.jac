"""Web fetch: the head of a web page, read the way linkding reads one: only from public addresses, a few redirects, a size limit."""

import socket;
import ssl;
import from http.client { HTTPResponse, HTTPConnection, HTTPSConnection }
import from urllib.parse { urlsplit, urljoin }

"""The text of the page at `url`, all of it or (`head_only`) up to the end of its head, or None when it cannot be read."""
def fetch_page(url: str, head_only: bool = False) -> str | None;

"""The text of the page at `url` up to the end of its head, or None when it cannot be read."""
def fetch_head(url: str) -> str | None;
