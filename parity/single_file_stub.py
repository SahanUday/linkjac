#!/usr/bin/env python3
"""Stands in for the `single-file` command the original runs to snapshot a page (the real one needs a browser): fetches the address and writes it to the file, as `single-file <options> <url> <file>` would."""

import sys
import urllib.request

url, path = sys.argv[-2], sys.argv[-1]
with urllib.request.urlopen(url, timeout=10) as response:
    body = response.read()
with open(path, "wb") as out:
    out.write(b"<!-- saved by the single-file stand-in -->\n" + body)
