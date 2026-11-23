"""Background work: the one scheduled function that starts the jobs bookmarks are waiting for and keeps what finished jobs gave."""

import time;
import from stdjac { allroots, JobFailed }

"""Starts the jobs bookmarks are waiting for (an icon for a site, a snapshot for a pending asset), keeps what finished jobs gave, and gives bookmarks the icon of their site."""
@schedule(interval=2.0)
def run_background_work;
