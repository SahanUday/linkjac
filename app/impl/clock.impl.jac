import from datetime { timedelta, timezone }

# WORKAROUND(GAP-029): a time-zone-aware datetime in a node field is rejected by a served app, so times are naive UTC.
impl now_utc -> datetime {
    return datetime.now(timezone.utc).replace(tzinfo=None);
}

impl read_instant(text: str) -> datetime | None {
    try {
        parsed = datetime.fromisoformat(text.strip().replace("Z", "+00:00"));
    } except ValueError {
        return None;
    }
    if parsed.tzinfo is None {
        return parsed;
    }
    return parsed.astimezone(timezone.utc).replace(tzinfo=None);
}

impl epoch_of(stamp: datetime) -> int {
    return int((stamp - datetime(1970, 1, 1)).total_seconds());
}

impl read_epoch(text: str) -> datetime | None {
    try {
        seconds = int(text);
    } except (ValueError, OverflowError) {
        # WORKAROUND(GAP-041): int is 64-bit, so a longer number raises here; it is no date, what the original does was not run.
        return None;
    }
    for divisor in [1, 1000, 1000000] {
        try {
            return datetime(1970, 1, 1) + timedelta(seconds=seconds / divisor);
        } except (OverflowError, ValueError) {
            continue;
        }
    }
    return None;
}
