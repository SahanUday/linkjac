"""Tests of the address guard: the cases of linkding's own tests (bookmarks/tests/test_http_client.py) that need no network."""

test "internal, embedded and multicast addresses are not public" {
    for address in [
        "127.0.0.1",
        "127.255.255.254",
        "::1",
        "0.0.0.0",
        "::",
        "169.254.169.254",
        "169.254.1.1",
        "fe80::1",
        "10.0.0.1",
        "172.16.0.1",
        "172.31.255.255",
        "192.168.1.1",
        "fd12:3456::1",
        "100.64.0.1",
        "100.127.255.255",
        "::ffff:127.0.0.1",
        "::ffff:10.0.0.1",
        "::ffff:169.254.169.254",
        "2002:7f00:1::",
        "2001:0::7f00:1",
        "64:ff9b::7f00:1",
        "64:ff9b:1::7f00:1",
        "::127.0.0.1",
        "::a9fe:a9fe",
        "fec0::1",
        "feff::1",
        "224.0.0.1",
        "ff02::1",
    ] {
        assert not is_public(address), address;
    }
}

test "public addresses are public" {
    for address in [
        "8.8.8.8",
        "93.184.216.34",
        "2606:4700::1111",
        "2a00:1450:4001:80b::200e",
        "::ffff:8.8.8.8",
    ] {
        assert is_public(address), address;
    }
}

test "an allow list takes names, addresses, ranges and a star, and drops a bad range" {
    allowed = read_allow_list(
        " Example.COM ,.internal, 10.1.0.0/16 ,[fd00::1],bad/range,, 192.168.0.7"
    );
    assert not allowed.everything;
    assert allowed.host_names == ["example.com", ".internal"];
    assert [str(each) for each in allowed.networks] == [
        "10.1.0.0/16",
        "fd00::1/128",
        "192.168.0.7/32",
    ];
    assert read_allow_list("*").everything;
}

test "a loopback or private address is refused and a name that does not resolve gives nothing" {
    assert checked_addresses("10.1.2.3", 80) is None;
    assert checked_addresses("127.0.0.1", 80) is None;
    assert checked_addresses("no-such-name.invalid", 80) is None;
    assert checked_addresses("93.184.216.34", 80) == ["93.184.216.34"];
}
