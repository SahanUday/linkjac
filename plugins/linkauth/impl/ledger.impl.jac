impl Ledger.postinit {
    self.lock = threading.Lock();
}

impl Ledger.load {
    if not os.path.exists(self.path) {
        return;
    }
    with open(self.path, encoding="utf-8") as source {
        kept = json.load(source);
    }
    for row in kept["users"] {
        self.users[row["username"]] = User(
            username=row["username"],
            password=row["password"],
            email=row["email"],
            first_name=row["first_name"],
            last_name=row["last_name"],
            is_staff=row["is_staff"],
            is_superuser=row["is_superuser"],
            is_active=row["is_active"],
            date_joined=row["date_joined"],
        );
    }
    for row in kept["tokens"] {
        self.tokens[row["key"]] = ApiToken(
            key=row["key"], username=row["username"], name=row["name"], created=row["created"]
        );
    }
    for row in kept["sessions"] {
        self.sessions[row["digest"]] = LoginSession(
            digest=row["digest"], username=row["username"], expires=row["expires"]
        );
    }
}

def user_row(user: User) -> dict[str, any] {
    return {
        "username": user.username,
        "password": user.password,
        "email": user.email,
        "first_name": user.first_name,
        "last_name": user.last_name,
        "is_staff": user.is_staff,
        "is_superuser": user.is_superuser,
        "is_active": user.is_active,
        "date_joined": user.date_joined,
    };
}

impl Ledger.save {
    kept = {
        "users": [user_row(u) for u in self.users.values()],
        "tokens": [
            {"key": t.key, "username": t.username, "name": t.name, "created": t.created}
            for t in self.tokens.values()
        ],
        "sessions": [
            {"digest": s.digest, "username": s.username, "expires": s.expires}
            for s in self.sessions.values()
        ],
    };
    # WORKAROUND(GAP-055): the data directory may not exist yet.
    os.makedirs(os.path.dirname(self.path) or ".", exist_ok=True);
    fresh = self.path + ".new";
    # The file holds password hashes and API keys, so only its owner may read it.
    with os.fdopen(os.open(fresh, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600), "w") as out {
        json.dump(kept, out);
        out.flush();
        os.fsync(out.fileno());
    }
    os.replace(fresh, self.path);
}

impl new_key -> str {
    return secrets.token_hex(20);
}

impl digest(token: str) -> str {
    return hashlib.sha256(token.encode("utf-8")).hexdigest();
}
