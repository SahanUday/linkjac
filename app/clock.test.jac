test "the time has no time zone and is close to the real UTC time" {
    stamp = now_utc();
    assert stamp.tzinfo is None;
    assert abs((stamp - datetime.utcnow()).total_seconds()) < 5.0;
}

test "an ISO time becomes naive UTC and anything else is None" {
    assert read_instant("2026-11-23T09:56:08.051886Z") == datetime(2026, 11, 23, 9, 56, 8, 51886);
    assert read_instant("2020-01-02T03:04:05+02:00") == datetime(2020, 1, 2, 1, 4, 5);
    assert read_instant("2020-01-02T03:04:05") == datetime(2020, 1, 2, 3, 4, 5);
    assert read_instant("not a date") is None;
}

test "seconds since 1970 read as naive UTC and write back whole" {
    assert read_epoch("1") == datetime(1970, 1, 1, 0, 0, 1);
    assert read_epoch("1700000000") == datetime(2023, 11, 14, 22, 13, 20);
    assert epoch_of(datetime(2023, 11, 14, 22, 13, 20, 999999)) == 1700000000;
}

test "a timestamp too large for seconds is read as milliseconds, then microseconds" {
    assert read_epoch("1700000000000") == datetime(2023, 11, 14, 22, 13, 20);
    assert read_epoch("1700000000000000") == datetime(2023, 11, 14, 22, 13, 20);
    assert read_epoch("99999999999999999999") is None;
    assert read_epoch("yesterday") is None;
}
