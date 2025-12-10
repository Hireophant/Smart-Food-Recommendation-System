"""Rate limiting middleware using SlowAPI."""

from slowapi import Limiter
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from fastapi import Request
from fastapi.responses import JSONResponse

# Create a global limiter instance using IP address as the key
limiter = Limiter(key_func=get_remote_address)


# Custom handler for rate limit exceeded
def _rate_limit_handler(request: Request, exc: RateLimitExceeded):
    return JSONResponse(
        status_code=429,
        content={
            "detail": "Too many requests. Please slow down.",
            "error": str(exc)
        }
    )


# Middleware wrapper for use in main.py
def apply_rate_limit_middleware(app):
    """
    Attach SlowAPI middleware & exception handler.
    """
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_handler)
    app.add_middleware(SlowAPIMiddleware)
