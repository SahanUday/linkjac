"""Ledger: the accounts, API tokens and sign-in sessions, kept in one JSON file that is replaced whole."""

import json;
import os;
import hashlib;
import secrets;
import threading;

"""An account, with the fields linkding's user has; `password` is a hash, "" for none usable."""
# WORKAROUND(GAP-027): users cannot be kept under root, so the plugin keeps them.
obj User {
    has username: str,
        password: str = "",
        email: str = "",
        first_name: str = "",
        last_name: str = "",
        is_staff: bool = False,
        is_superuser: bool = False,
        is_active: bool = True,
        date_joined: float = 0.0;
}

"""A named API token of a user; it lasts until it is removed."""
obj ApiToken {
    has key: str,
        username: str,
        name: str,
        created: float = 0.0;
}

"""A sign-in that ends at `expires`; only the digest of its token is kept."""
obj LoginSession {
    has digest: str,
        username: str,
        expires: float;
}

"""Everything the plugin keeps, read from and written to the file at `path`."""
# WORKAROUND(GAP-051): a plugin cannot use root or the store, so this is persistence of its own.
obj Ledger {
    has path: str,
        users: dict[str, User] = {},
        tokens: dict[str, ApiToken] = {},
        sessions: dict[str, LoginSession] = {};
    has lock: threading.Lock postinit;

    def postinit;

    """Reads what the file holds; a file that is not there yet holds nothing."""
    def load;

    """Replaces the file with what is held now; the caller holds `lock`."""
    def save;
}

"""A new random token: 40 hex digits, the shape of linkding's API keys."""
def new_key -> str;

"""What is kept in place of a session's token."""
def digest(token: str) -> str;
