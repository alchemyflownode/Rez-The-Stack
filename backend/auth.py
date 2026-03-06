"""
Authentication and JWT token management
"""
import logging
import jwt
import uuid
from datetime import datetime, timedelta
from typing import Dict, Any, Optional
from fastapi import HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials  # FIXED IMPORT
from fastapi import Request

logger = logging.getLogger(__name__)

# Configuration
JWT_SECRET = "your-secret-key-change-in-production"
JWT_ALGORITHM = "HS256"
JWT_EXPIRATION_DAYS = 7


def create_session_id() -> str:
    """Generate a unique session ID"""
    return str(uuid.uuid4())


def create_access_token(session_id: str) -> str:
    """
    Create a JWT access token for a session
    
    Args:
        session_id: Unique session identifier
        
    Returns:
        JWT token string
    """
    try:
        payload = {
            "session_id": session_id,
            "exp": datetime.utcnow() + timedelta(days=JWT_EXPIRATION_DAYS),
            "iat": datetime.utcnow(),
            "type": "access"
        }
        token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
        logger.info(f"Created token for session: {session_id}")
        return token
    except Exception as e:
        logger.error(f"Failed to create token: {e}", exc_info=True)
        raise


def verify_token(token: str) -> Dict[str, Any]:
    """
    Verify and decode JWT token
    
    Args:
        token: JWT token string
        
    Returns:
        Decoded token payload
        
    Raises:
        HTTPException: Invalid or expired token
    """
    try:
        if token.startswith("Bearer "):
            token = token[7:]
            
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        logger.warning(f"Token expired: {token[:20]}...")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except jwt.InvalidTokenError as e:
        logger.warning(f"Invalid token: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except Exception as e:
        logger.error(f"Token verification error: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Token verification failed"
        )


async def verify_session_from_request(request: Request) -> str:
    """
    Extract and verify session ID from request
    Checks Authorization header or X-Session-ID header
    
    Args:
        request: FastAPI request object
        
    Returns:
        Valid session_id
        
    Raises:
        HTTPException: Missing or invalid session
    """
    # Try Authorization header first
    auth_header = request.headers.get("Authorization", "")
    if auth_header:
        try:
            token = auth_header.replace("Bearer ", "")
            payload = verify_token(token)
            return payload.get("session_id")
        except HTTPException:
            raise
    
    # Try X-Session-ID header
    session_id = request.headers.get("X-Session-ID", "")
    if session_id:
        return session_id
    
    # Allow first-time users without token (generates new session)
    return create_session_id()


# Fixed: Use HTTPAuthorizationCredentials instead of HTTPAuthCredentials
security = HTTPBearer(auto_error=False)


async def get_current_session(
    credentials: Optional[HTTPAuthorizationCredentials] = None,  # FIXED
    request: Request = None
) -> str:
    """
    FastAPI dependency to get current session ID
    Usage: async def endpoint(session: str = Depends(get_current_session)):
    """
    if credentials:
        try:
            payload = verify_token(credentials.credentials)
            return payload.get("session_id")
        except HTTPException:
            raise
    
    # Fallback to X-Session-ID header
    if request:
        session_id = request.headers.get("X-Session-ID")
        if session_id:
            return session_id
    
    # Generate new session
    return create_session_id()