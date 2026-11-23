"""Clock: the one place the current time is read, in the form the store can keep."""

import from datetime { datetime }

"""The current UTC time without a time zone."""
def now_utc -> datetime;

"""A time written as ISO 8601 (with a Z or an offset, or none, meaning UTC) as naive UTC, or None when it is not one."""
def read_instant(text: str) -> datetime | None;

"""A time as whole seconds since 1970-01-01 UTC, the way Netscape files write dates."""
def epoch_of(stamp: datetime) -> int;

"""A time written as seconds since 1970 as naive UTC; a value too large for seconds is tried as milliseconds, then microseconds. None when it is not a whole number or fits none of them."""
def read_epoch(text: str) -> datetime | None;
