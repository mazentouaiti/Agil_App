from django.contrib.auth import backends
from django.contrib.auth import get_user_model
from django.db.models import Q

class EmailAuthBackend(backends.ModelBackend):
    def authenticate(self, request, username=None, password=None, **kwargs):
        UserModel = get_user_model()
        try:
            user = UserModel.objects.get(
                Q(email__iexact=username)
            )
            if user.check_password(password) and self.user_can_authenticate(user):
                return user
        except UserModel.DoesNotExist:
            return None