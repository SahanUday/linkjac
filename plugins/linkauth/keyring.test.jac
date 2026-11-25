"""Tests of the keyring: sign-in, tokens, sessions and who may make accounts."""

import tempfile;
import from common.contract { Secret }

"""A host that gives a data directory and the two superuser settings."""
obj FakeHost(AuthHost) {
    has directory: str;

    def data_dir -> str {
        return self.directory;
    }

    def secret(s: Secret) -> str {
        return {"LD_SUPERUSER_NAME": "root", "LD_SUPERUSER_PASSWORD": "root-pass"}.get(
            s.variable, ""
        );
    }

    def upgraded(what: str) {}

    def windowed -> bool {
        return False;
    }

    def consume_limit(scope: str, actor: str, limit: int, seconds: int) -> int {
        return 0;
    }
}

def opened(directory: str) -> LinkAuth {
    keyring = LinkAuth(rounds=10);
    keyring.open(FakeHost(directory=directory));
    return keyring;
}

def refusal(keyring: LinkAuth, action: str, given: dict[str, str]) -> str {
    try {
        keyring.answer(action, given, "here");
    } except Rejected as e {
        return e.detail;
    }
    return "";
}

def bearer(token: str) -> dict[str, str] {
    return {"authorization": "Bearer " + token};
}

glob amy: dict[str, str] = {"username": "amy", "password": "amy-pass"},
     as_root: dict[str, str] = {"admin": "root", "admin_password": "root-pass"};

test "a credential is read under either keyword in any case, and under nothing else" {
    for header in ["Token k", "token k", "BEARER k"] {
        assert credential({"authorization": header}) == "k", header;
    }
    for header in ["", "k", "Basic k", "Token", "Token k more"] {
        assert credential({"authorization": header}) == "", header;
    }
}

test "there is no sign-up, and only a superuser makes an account" {
    with tempfile.TemporaryDirectory() as top {
        keyring = opened(top);
        assert refusal(keyring, "register", amy) == "There is no such way to sign in.";
        assert [a.name for a in keyring.asks({}).actions] == ["login"];
        assert refusal(keyring, "add_user", amy) == wrong_sign_in;
        assert refusal(keyring, "add_user", {**amy, **as_root}) == "";
        assert refusal(keyring, "add_user", {**amy, **as_root})
            == "A user with that username already exists.";
        assert refusal(
            keyring,
            "add_user",
            {"admin": "amy", "admin_password": "amy-pass", "username": "bo", "password": "bo-pass"},
        )
            == "Only an admin makes accounts.";
        for bad in ["", "has space", "x" * 151] {
            assert refusal(keyring, "add_user", {**as_root, "username": bad, "password": "p"})
                != "";
        }
    }
}

test "a token stays through sign-out and a restart until it is removed by its owner" {
    with tempfile.TemporaryDirectory() as top {
        keyring = opened(top);
        keyring.answer("add_user", {**amy, **as_root}, "here");
        made = keyring.answer("create_token", {**amy, "name": "  "}, "here");
        assert made.name == "API Token" and len(made.token) == 40;
        session = keyring.answer("login", amy, "here");
        assert keyring.caller(bearer(session.token)) == "amy";
        keyring.leave(bearer(made.token));
        keyring.leave(bearer(session.token));
        assert keyring.caller(bearer(session.token)) is None;
        again = opened(top);
        assert again.caller({"authorization": "Token " + made.token}) == "amy";
        assert refusal(
            again, "delete_token", {"username": "root", "password": "root-pass", "key": made.token}
        )
            == "API token does not exist";
        again.answer("delete_token", {**amy, "key": made.token}, "here");
        assert again.caller(bearer(made.token)) is None;
    }
}

test "a session ends at its time, and an inactive account is no one" {
    with tempfile.TemporaryDirectory() as top {
        keyring = opened(top);
        keyring.answer("add_user", {**amy, **as_root}, "here");
        keyring.session_seconds = -1.0;
        assert keyring.caller(bearer(keyring.answer("login", amy, "here").token)) is None;
        token = keyring.answer("create_token", amy, "here").token;
        keyring.ledger.users["amy"].is_active = False;
        assert keyring.caller(bearer(token)) is None;
        assert refusal(keyring, "login", amy) == wrong_sign_in;
    }
}
