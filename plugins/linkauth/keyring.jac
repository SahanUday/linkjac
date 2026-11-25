"""Keyring: the auth abstraction as linkding has it: Token or Bearer credentials, named API tokens, no sign-up, accounts made by an admin."""

import os;
import re;
import time;
import from common.contract { Host, Secret }
import from auth.contract { Auth, AuthHost, Session, SignIn, SignInField, SignInAction, Rejected }

# WORKAROUND(GAP-034, GAP-046, GAP-050): the standard accounts plugin reads only Bearer, keeps sign-up open and cannot be extended.
"""Accounts and API tokens; the first account comes from LD_SUPERUSER_NAME and LD_SUPERUSER_PASSWORD, as linkding's does."""
obj LinkAuth(Auth) {
    """`path` is the file (`linkauth.json` in the app's data directory unless given), `session_seconds` how long a sign-in lasts (linkding's two weeks), `rounds` the rounds of a password's hash."""
    has path: str = "",
        session_seconds: float = 1209600.0,
        rounds: int = 600000,
        superuser_name: Secret = Secret(variable="LD_SUPERUSER_NAME"),
        superuser_password: Secret = Secret(variable="LD_SUPERUSER_PASSWORD");

    has ledger: Ledger | None postinit;

    def postinit;

    def open(host: dyn AuthHost);

    def caller(headers: dict[str, str]) -> str | None;

    def asks(headers: dict[str, str]) -> SignIn;

    def answer(action: str, given: dict[str, str], client: str) -> Session;

    def leave(headers: dict[str, str]);

    """The active account these name and password belong to, or `Rejected` in linkding's words."""
    def checked_user(username: str, password: str) -> User;

    """Makes an account, which an admin asks for with their own name and password."""
    def add_user(given: dict[str, str]) -> Session;

    """Makes a named API token for the account whose name and password are given."""
    def create_token(given: dict[str, str]) -> Session;

    """Removes one of that account's API tokens."""
    def delete_token(given: dict[str, str]) -> Session;
}

"""The credential of an `Authorization: Token <key>` or `Bearer <key>` header, the keyword in any case, or ""."""
def credential(headers: dict[str, str]) -> str;

"""Whether `username` is one linkding's user model takes: up to 150 letters, digits and @ . + - _."""
def is_username(username: str) -> bool;
