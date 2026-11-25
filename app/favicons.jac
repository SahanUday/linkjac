"""Favicons: a site's icon, kept once under a name made from the site's address and shared by every bookmark of the site, as linkding keeps them."""

import os;
import re;
import mimetypes;
import from urllib.parse { urlsplit }

"""A kept icon: its file name, its content type and its bytes as base64 text."""
# WORKAROUND(GAP-049): no file storage, so the icon is base64 text in the node.
node Favicon {
    has file: str,
        content_type: str,
        data: str;
}

"""The name, without extension, that the icon of the site of `url` is kept under."""
def favicon_base_name(url: str) -> str;

"""The address the icon of the site of `url` is asked for: LD_FAVICON_PROVIDER with {url} and {domain} filled in."""
def provider_address(url: str) -> str;

"""The kept icon whose name is `file`, or None."""
def find_favicon(file: str) -> Favicon | None;

"""The kept icon of the site named `base`, whatever its extension, or None."""
def find_favicon_of_site(base: str) -> Favicon | None;

"""Keeps an icon for the site named `base`; its extension comes from the content type."""
def keep_favicon(base: str, content_type: str, data: str) -> Favicon;
