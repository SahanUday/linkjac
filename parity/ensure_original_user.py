"""Creates the parity users and their API tokens in the original linkding and prints TOKEN=<key>, TOKEN_OTHER=<key> and TOKEN_JOBS=<key>. Run through manage.py shell."""

from bookmarks.models import ApiToken
from django.contrib.auth import get_user_model

# parity3 is the one account the background-job checks use, so no other check sees a favicon or a snapshot appear.
for name, label in (("parity", "TOKEN"), ("parity2", "TOKEN_OTHER"), ("parity3", "TOKEN_JOBS")):
    user, _ = get_user_model().objects.get_or_create(username=name, defaults={"is_superuser": True, "is_staff": True})
    user.set_password("parity-pass")
    user.save()
    user.profile.enable_favicons = name == "parity3"
    user.profile.enable_automatic_html_snapshots = name == "parity3"
    user.profile.save()
    token = ApiToken.objects.filter(user=user, name="parity").first() or ApiToken.objects.create(user=user, name="parity")
    print(f"{label}={token.key}")
