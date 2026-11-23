"""Tag dialog: the small form that makes a tag (id 0) or renames one, shown over nothing else, as linkding shows it."""

import from "@jac/runtime" { navigate, sign_in }

"""The Create Tag or Edit Tag dialog for tag `tag_id` (0 for a new one)."""
def:pub TagDialog(tag_id: int = 0) -> JsxElement;
