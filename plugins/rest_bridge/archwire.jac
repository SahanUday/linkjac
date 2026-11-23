graph layers {
    """Carries HTTP requests and hands the REST ones to the app as one call."""
    layer transport { bridge; }
}
