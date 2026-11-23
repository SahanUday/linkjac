glob default_provider: str = "https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url={url}&size=32";

def site_of(url: str) -> tuple[str, str] {
    parts = urlsplit(url);
    return (f"{parts.scheme}://{parts.hostname}", parts.hostname or "");
}

impl favicon_base_name(url: str) -> str {
    return re.sub(r"\W+", "_", site_of(url)[0]);
}

impl provider_address(url: str) -> str {
    (site, domain) = site_of(url);
    return os.getenv("LD_FAVICON_PROVIDER", default_provider).replace("{url}", site).replace(
        "{domain}", domain
    );
}

impl find_favicon(file: str) -> Favicon | None {
    for each in [root.shared --> [?:Favicon]] {
        if each.file == file {
            return each;
        }
    }
    return None;
}

impl find_favicon_of_site(base: str) -> Favicon | None {
    for each in [root.shared --> [?:Favicon]] {
        if os.path.splitext(each.file)[0] == base {
            return each;
        }
    }
    return None;
}

impl keep_favicon(base: str, content_type: str, data: str) -> Favicon {
    extension = mimetypes.guess_extension(content_type) or "";
    return root.shared ++> Favicon(file=base + extension, content_type=content_type, data=data);
}
