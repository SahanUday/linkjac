"""Creates the parity user and API token in the original linkding and prints TOKEN=<key>. Run through manage.py shell."""

from bookmarks.models import ApiToken
from django.contrib.auth import get_user_model

user, _ = get_user_model().objects.get_or_create(username="parity", defaults={"is_superuser": True, "is_staff": True})
user.set_password("parity-pass")
user.save()
token = ApiToken.objects.filter(user=user, name="parity").first() or ApiToken.objects.create(user=user, name="parity")
print("TOKEN=" + token.key)
