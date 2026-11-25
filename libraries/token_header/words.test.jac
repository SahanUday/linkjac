"""Tests of the header's words."""

test "a header is read under either keyword in any case, and under nothing else" {
    for header in ["Token k", "token k", "BEARER k"] {
        assert token_words(header)[1] == "k", header;
    }
    assert token_words("Token") == ["Token"];
    assert token_words("bearer a b") == ["bearer", "a", "b"];
    for header in ["", "k", "Basic k", "Key k"] {
        assert token_words(header) == [], header;
    }
}
