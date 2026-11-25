def derive(password: str, salt: str, rounds: int) -> str {
    return hashlib.pbkdf2_hmac(
        "sha256", password.encode("utf-8"), salt.encode("ascii"), rounds
    ).hex();
}

impl hash_password(password: str, rounds: int) -> str {
    salt = secrets.token_hex(16);
    return f"{rounds}${salt}${derive(password, salt, rounds)}";
}

impl password_matches(password: str, kept: str) -> bool {
    parts = kept.split("$");
    if len(parts) != 3 {
        return False;
    }
    return secrets.compare_digest(derive(password, parts[1], int(parts[0])), parts[2]);
}
