test "a site's icon is named from its scheme and host, not its path" {
    assert favicon_base_name("http://127.0.0.1:9100/page?x=1") == "http_127_0_0_1";
    assert favicon_base_name("https://example.com/a/b") == "https_example_com";
}

test "the default provider is asked for the site's address" {
    assert "url=https://example.com&size=32" in provider_address("https://example.com/a");
}

test "a kept icon is found by its file and by its site, with the extension of its content type" {
    kept = keep_favicon("https_tested_example", "image/png", "AAAA");
    assert kept.file == "https_tested_example.png";
    assert find_favicon("https_tested_example.png") is kept;
    assert find_favicon_of_site("https_tested_example") is kept;
    assert find_favicon("nothing.png") is None;
}
