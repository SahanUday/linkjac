graph layers {
    """Password hashing."""
    layer secrets_kept { passwords; }

    """The accounts, tokens and sessions kept in a file."""
    layer records { ledger; }

    """The auth abstraction carried out: who a caller is, and signing in."""
    layer auth { keyring; }
}

graph import {
    edge Stores: records --> auth;
    edge Hashes: secrets_kept --> auth;

    passwords ++> keyring { hash_password, password_matches }
    ledger ++> keyring { Ledger, User, ApiToken, LoginSession, new_key, digest }
}
