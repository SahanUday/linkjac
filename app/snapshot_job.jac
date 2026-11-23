"""Snapshot job: a page fetched apart from the server, which cannot see the graph, so it gives back the text the server keeps."""

"""The text of the page at `address`; the job fails when the page cannot be read."""
@job
def load_snapshot(address: str, note: JobNote) -> str;
