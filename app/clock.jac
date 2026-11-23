"""Clock: the one place the current time is read, in the form the store can keep."""

import from datetime { datetime }

"""The current UTC time without a time zone."""
def now_utc -> datetime;

"""A time written as ISO 8601 (with a Z or an offset, or none, meaning UTC) as naive UTC, or None when it is not one."""
def read_instant(text: str) -> datetime | None;
