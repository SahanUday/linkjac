"""Creates the two parity users and their API tokens in the original linkding and prints TOKEN=<key> and TOKEN_OTHER=<key>. Run through manage.py shell."""

from bookmarks.models import ApiToken
from django.contrib.auth import get_user_model

for name, label in (("parity", "TOKEN"), ("parity2", "TOKEN_OTHER")):
    user, _ = get_user_model().objects.get_or_create(username=name, defaults={"is_superuser": True, "is_staff": True})
    user.set_password("parity-pass")
    user.save()
    token = ApiToken.objects.filter(user=user, name="parity").first() or ApiToken.objects.create(user=user, name="parity")
    print(f"{label}={token.key}")
