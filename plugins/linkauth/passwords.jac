"""Passwords: a password turned into a salted hash, and a try held against it."""

import hashlib;
import secrets;

"""The text kept for `password`: the number of rounds, the salt and the PBKDF2-SHA256 hash."""
def hash_password(password: str, rounds: int) -> str;

"""Whether `password` is the one `kept` was made from; nothing matches an empty `kept` (an account with no usable password)."""
def password_matches(password: str, kept: str) -> bool;
