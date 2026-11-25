impl token_words(header: str) -> list[str] {
    words = header.split();
    return words if words and words[0].lower() in ["token", "bearer"] else [];
}
