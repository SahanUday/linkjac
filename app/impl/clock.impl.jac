import from datetime { timezone }

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
