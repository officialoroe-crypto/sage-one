"""Database package bootstrap.

Import additive models here so Base.metadata.create_all() registers profile,
user memory, and world-intelligence tables alongside the existing SAGE schema.
"""

from identity.profile import UserProfile  # noqa: F401
from identity.memory import ProfileMemory  # noqa: F401
from world_intelligence.models import (  # noqa: F401
    UpgradeProposal,
    WorldKnowledge,
    WorldSignal,
)
