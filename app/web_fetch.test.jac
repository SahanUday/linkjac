test "a made-up scheme and an internal address are not fetched" {
    assert fetch_head("ftp://example.com/") is None;
    assert fetch_head("http://127.0.0.1:9/") is None;
}
