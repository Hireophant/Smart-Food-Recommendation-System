"""Rate limiting middleware using SlowAPI."""

from slowapi import Limiter
from slowapi.util import get_remote_address

# Create a global limiter instance using IP address as the key
limiter = Limiter(key_func=get_remote_address)
