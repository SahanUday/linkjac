test "a page's first title, description and image are read, the plain description before the Open Graph one" {
    reader = MetadataReader();
    reader.feed(
        '<head><title> One </title><title>Two</title><meta property="og:description" content="og"><meta name="description" content=" plain "><meta property="og:image" content="/i.png"></head>',
    );
    assert reader.title == " One ";
    assert reader.description == "plain";
    assert reader.og_description == "og";
    assert reader.image == "/i.png";
}

test "a page with no head says nothing" {
    reader = MetadataReader();
    reader.feed("<body>text</body>");
    assert reader.title is None;
    assert reader.description == "";
}
