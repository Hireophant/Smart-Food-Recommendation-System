"""Authentication middleware for JWT verification."""

import os
from typing import Dict

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt, ExpiredSignatureError
from utils import Logger

# HTTP Bearer token extractor
__http_bearer = HTTPBearer()

async def VerifyAccessToken(
    credentials: HTTPAuthorizationCredentials = Depends(__http_bearer),
) -> Dict:
    """
    Verify the JWT access token from Supabase.

    Validates the token signature and expiration using the SUPABASE_JWT_SECRET
    from environment variables. Does not verify user existence in the database.

    Args:
        credentials: The HTTP Authorization Bearer credentials containing the token.

    Returns:
        Dict: The decoded JWT payload containing user information.

    Raises:
        HTTPException: 401 if token is invalid, expired, or JWT secret is not configured.
    """
    # Get JWT secret from environment
    jwt_secret = os.getenv("SUPABASE_JWT_SECRET")
    if not jwt_secret:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="JWT authentication is not properly configured",
        )

    token = credentials.credentials

    try:
        # Decode and verify the JWT token
        # Using HS256 algorithm as specified in general.json config
        payload = jwt.decode(
            token,
            jwt_secret,
            algorithms=["HS256"],
            options={"verify_aud": False}
        )

        return payload

    except ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Access token has expired",
        )
    except JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid access token",
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token verification failed: {str(e)}",
        )
