"""Web tags: the tags table of the tags page, and making, renaming and removing a tag from it."""

"""A tag as the table shows it: its id, its name and how many bookmarks carry it."""
obj TagRow {
    has id: int = 0,
        name: str = "",
        count: int = 0;
}

"""What the tags page shows: the rows that match, and how many tags the caller has in all."""
obj TagTable {
    has rows: list[TagRow] = [],
        total: int = 0;
}

"""The tags of the caller whose name has `search` in it, ignoring case, in the order `sort` names: `name_asc`, `name_desc`, `count_desc` or `count_asc`; `unused` keeps those on no bookmark."""
def:protect tag_table(search: str, sort: str, unused: bool) -> TagTable;

"""The name of the caller's tag `tag_id`, or "" when there is none."""
def:protect tag_name(tag_id: int) -> str;

"""Make a tag, or rename tag `tag_id` (0 makes one); the answer is an error message, or "" when it went through."""
def:protect save_tag(tag_id: int, name: str) -> str;

"""Remove the caller's tag `tag_id` from its bookmarks and from the caller."""
def:protect remove_tag(tag_id: int);

"""The rows sorted by `sort`."""
def sorted_rows(rows: list[TagRow], sort: str) -> list[TagRow];

"""A row's name in lower case, for sorting."""
def row_name_key(row: TagRow) -> str;

"""A row's bookmark count, for sorting."""
def row_count_key(row: TagRow) -> int;
