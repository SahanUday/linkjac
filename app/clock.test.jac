test "the time has no time zone and is close to the real UTC time" {
    stamp = now_utc();
    assert stamp.tzinfo is None;
    assert abs((stamp - datetime.utcnow()).total_seconds()) < 5.0;
}
