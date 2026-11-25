"""Tests of password hashing."""

test "only the password a hash was made from matches it, and two hashes of one password differ" {
    kept = hash_password("a-password", 10);
    assert password_matches("a-password", kept);
    assert not password_matches("A-password", kept);
    assert hash_password("a-password", 10) != kept;
}

test "an account with no usable password matches nothing" {
    assert not password_matches("", "");
}
