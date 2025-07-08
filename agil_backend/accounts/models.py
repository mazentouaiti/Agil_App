from django.db import models

from django.contrib.auth.models import AbstractUser

class User(AbstractUser):
    phone = models.CharField(max_length=20, blank=True)
    full_name = models.CharField(max_length=255, blank=True)  # New field
    
    # Remove these if not using groups/permissions
    groups = None
    user_permissions = None

    def __str__(self):
        return self.full_name or self.username