"""Root page: / sends a signed-in caller to the bookmark list, and asks anyone else to sign in first."""

import from "@jac/runtime" { sign_in, navigate }

def:pub page -> JsxPage;
