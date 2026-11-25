glob wrong_sign_in: str = "Your username and password didn't match. Please try again.";

def rejected(why: str) -> Rejected {
    return Rejected(detail=why, retry_after=0);
}

impl credential(headers: dict[str, str]) -> str {
    words = headers.get("authorization", "").split();
    if len(words) == 2 and words[0].lower() in ["token", "bearer"] {
        return words[1];
    }
    return "";
}

impl is_username(username: str) -> bool {
    return 0 < len(username) <= 150 and re.fullmatch(r"[\w.@+-]+", username) is not None;
}

impl LinkAuth.postinit {
    self.ledger = None;
}

impl LinkAuth.open(host: dyn AuthHost) {
    ledger = Ledger(path=self.path or os.path.join(host.data_dir(), "linkauth.json"));
    ledger.load();
    self.ledger = ledger;
    name = host.secret(self.superuser_name);
    if name and name not in ledger.users {
        password = host.secret(self.superuser_password);
        with ledger.lock {
            ledger.users[name] = User(
                username=name,
                password=hash_password(password, self.rounds) if password else "",
                is_staff=True,
                is_superuser=True,
                date_joined=time.time(),
            );
            ledger.save();
        }
    }
}

impl LinkAuth.caller(headers: dict[str, str]) -> str | None {
    given = credential(headers);
    if not given {
        return None;
    }
    with self.ledger.lock {
        username = "";
        if given in self.ledger.tokens {
            username = self.ledger.tokens[given].username;
        } else {
            session = self.ledger.sessions.get(digest(given));
            if session is not None and session.expires > time.time() {
                username = session.username;
            }
        }
        user = self.ledger.users.get(username);
        return user.username if user is not None and user.is_active else None;
    }
}

impl LinkAuth.asks(headers: dict[str, str]) -> SignIn {
    return SignIn(
        fields=[
            SignInField(name="username", label="Username", secret=False, choices=[]),
            SignInField(name="password", label="Password", secret=True, choices=[]),
        ],
        actions=[
            SignInAction(
                name="login", label="Login", needs=["username", "password"], redirect="", keeps={}
            ),
        ],
        redirect="",
        session=None,
    );
}

impl LinkAuth.checked_user(username: str, password: str) -> User {
    with self.ledger.lock {
        user = self.ledger.users.get(username);
    }
    if user is None or not password_matches(password, user.password) or not user.is_active {
        # An unknown name costs a hash too, so the time taken does not tell which names exist.
        if user is None {
            hash_password(password, self.rounds);
        }
        raise rejected(wrong_sign_in);
    }
    return user;
}

def sign_in_session(auth: LinkAuth, given: dict[str, str]) -> Session {
    user = auth.checked_user(given.get("username", ""), given.get("password", ""));
    token = new_key() + new_key();
    now = time.time();
    with auth.ledger.lock {
        for old in [s.digest for s in auth.ledger.sessions.values() if s.expires <= now] {
            del auth.ledger.sessions[old];
        }
        auth.ledger.sessions[digest(token)] = LoginSession(
            digest=digest(token), username=user.username, expires=now + auth.session_seconds
        );
        auth.ledger.save();
    }
    return Session(user=user.username, token=token, name="");
}

# WORKAROUND(GAP-053): the app cannot call this plugin, so accounts and tokens are made by actions that take a name and password.
impl LinkAuth.answer(action: str, given: dict[str, str], client: str) -> Session {
    if action == "login" {
        return sign_in_session(self, given);
    }
    if action == "add_user" {
        return self.add_user(given);
    }
    if action == "create_token" {
        return self.create_token(given);
    }
    if action == "delete_token" {
        return self.delete_token(given);
    }
    raise rejected("There is no such way to sign in.");
}

impl LinkAuth.add_user(given: dict[str, str]) -> Session {
    admin = self.checked_user(given.get("admin", ""), given.get("admin_password", ""));
    if not admin.is_superuser {
        raise rejected("Only an admin makes accounts.");
    }
    username = given.get("username", "");
    password = given.get("password", "");
    if not is_username(username) or not password {
        raise rejected("An account needs a valid username and a password.");
    }
    made = User(
        username=username,
        password=hash_password(password, self.rounds),
        email=given.get("email", ""),
        first_name=given.get("first_name", ""),
        last_name=given.get("last_name", ""),
        date_joined=time.time(),
    );
    with self.ledger.lock {
        if username in self.ledger.users {
            raise rejected("A user with that username already exists.");
        }
        self.ledger.users[username] = made;
        self.ledger.save();
    }
    return Session(user=username, token="", name="");
}

impl LinkAuth.create_token(given: dict[str, str]) -> Session {
    user = self.checked_user(given.get("username", ""), given.get("password", ""));
    name = given.get("name", "").strip()[:128] or "API Token";
    made = ApiToken(key=new_key(), username=user.username, name=name, created=time.time());
    with self.ledger.lock {
        self.ledger.tokens[made.key] = made;
        self.ledger.save();
    }
    return Session(user=user.username, token=made.key, name=name);
}

impl LinkAuth.delete_token(given: dict[str, str]) -> Session {
    user = self.checked_user(given.get("username", ""), given.get("password", ""));
    with self.ledger.lock {
        found = self.ledger.tokens.get(given.get("key", ""));
        if found is None or found.username != user.username {
            raise rejected("API token does not exist");
        }
        del self.ledger.tokens[found.key];
        self.ledger.save();
    }
    return Session(user=user.username, token="", name=found.name);
}

impl LinkAuth.leave(headers: dict[str, str]) {
    given = credential(headers);
    with self.ledger.lock {
        # Signing out ends a session; an API token stays until it is removed.
        if given and digest(given) in self.ledger.sessions {
            del self.ledger.sessions[digest(given)];
            self.ledger.save();
        }
    }
}
