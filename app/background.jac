"""Background work: the one scheduled function that starts the jobs bookmarks are waiting for and keeps what finished jobs gave."""

import time;
import from stdjac { allroots, JobFailed }

"""Starts a favicon job for each site that has a bookmark without an icon, keeps the icons finished jobs fetched, and gives bookmarks the icon of their site."""
@schedule(interval=2.0)
def run_background_work;
