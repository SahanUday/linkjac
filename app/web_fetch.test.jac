test "a loopback or private address is refused and a made-up scheme is not fetched" {
    assert not may_connect("127.0.0.1");
    assert not may_connect("10.1.2.3");
    assert fetch_head("ftp://example.com/") is None;
    assert fetch_head("http://127.0.0.1:9/") is None;
}
