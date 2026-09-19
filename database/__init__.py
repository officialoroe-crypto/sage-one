"""Database package bootstrap.

Import additive identity models here so Base.metadata.create_all() registers
profile and user-scoped memory tables alongside the existing SAGE schema.
"""

from identity.profile import UserProfile  # noqa: F401
from identity.memory import ProfileMemory  # noqa: F401
