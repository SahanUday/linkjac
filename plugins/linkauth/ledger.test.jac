"""Tests of the ledger."""

import tempfile;

test "what is saved is read back, in a file only its owner reads" {
    with tempfile.TemporaryDirectory() as top {
        path = os.path.join(top, "not-there-yet", "ledger.json");
        written = Ledger(path=path);
        written.users["amy"] = User(username="amy", password="x", is_staff=True, date_joined=2.0);
        written.tokens["k"] = ApiToken(key="k", username="amy", name="phone", created=3.0);
        written.sessions["d"] = LoginSession(digest="d", username="amy", expires=4.0);
        written.save();
        read = Ledger(path=path);
        read.load();
        assert read.users == written.users;
        assert read.tokens == written.tokens;
        assert read.sessions == written.sessions;
        assert os.stat(path).st_mode & 0o777 == 0o600;
    }
}

test "a new key is 40 hex digits and no two are alike" {
    first = new_key();
    assert len(first) == 40 and all([c in "0123456789abcdef" for c in first]);
    assert new_key() != first;
}
