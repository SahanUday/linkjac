import from datetime { timezone }

# WORKAROUND(GAP-029): a time-zone-aware datetime in a node field is rejected by a served app, so times are naive UTC.
impl now_utc -> datetime {
    return datetime.now(timezone.utc).replace(tzinfo=None);
}
