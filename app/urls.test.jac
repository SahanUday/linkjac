test "scheme and host are lower-cased and the trailing slash goes" {
    assert normalize_url("HTTPS://Example.COM/a/b/") == "https://example.com/a/b";
}

test "query parameters are sorted" {
    assert normalize_url("http://e.com/?b=2&a=1") == "http://e.com?a=1&b=2";
}

test "the fragment and a port stay" {
    assert normalize_url("http://e.com:8080/x#top") == "http://e.com:8080/x#top";
}

test "blank text gives blank" {
    assert normalize_url("   ") == "";
}

test "outputs match the original's for odd URLs" {
    assert normalize_url("http://U:p@Host.com/?q=a b&z=") == "http://U:p@host.com?q=a%20b&z=";
    assert normalize_url("example.com/path") == "example.com/path";
    assert normalize_url("http://e.com/a%20b?x=%C3%A9&x=1") == "http://e.com/a%20b?x=1&x=%C3%A9";
    assert normalize_url("http://[::1]:80/a/") == "http://::1:80/a";
    assert normalize_url("mailto:a@b.c") == "mailto:a@b.c";
    assert normalize_url("http://e.com?") == "http://e.com";
    assert normalize_url("http://e.com/;p?q=1") == "http://e.com/;p?q=1";
}
