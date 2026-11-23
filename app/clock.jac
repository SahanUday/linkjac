"""Clock: the one place the current time is read, in the form the store can keep."""

import from datetime { datetime }

"""The current UTC time without a time zone."""
def now_utc -> datetime;
