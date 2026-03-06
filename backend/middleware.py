"""
Middleware for logging, error handling, and request tracking
"""
import logging
import time
import uuid
from datetime import datetime
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from pythonjsonlogger import jsonlogger

logger = logging.getLogger(__name__)


def setup_logging(log_level: str = "INFO", log_file: str = "logs/kernel.log"):
    """
    Configure structured JSON logging for the application
    
    Args:
        log_level: Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
        log_file: Path to log file
    """
    # Create logger
    logger = logging.getLogger()
    logger.setLevel(log_level)
    
    # Console handler with JSON formatter
    console_handler = logging.StreamHandler()
    json_formatter = jsonlogger.JsonFormatter(
        fmt="%(timestamp)s %(level)s %(name)s %(message)s"
    )
    console_handler.setFormatter(json_formatter)
    logger.addHandler(console_handler)
    
    # File handler
    try:
        import os
        os.makedirs("logs", exist_ok=True)
        
        file_handler = logging.FileHandler(log_file)
        file_handler.setFormatter(json_formatter)
        logger.addHandler(file_handler)
    except Exception as e:
        logger.error(f"Failed to setup file logging: {e}")


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """
    Middleware for logging all HTTP requests and responses
    Records timing, status codes, and request metadata
    """
    
    async def dispatch(self, request: Request, call_next) -> Response:
        # Generate unique request ID
        request_id = str(uuid.uuid4())
        start_time = time.time()
        
        # Store in request for access in handlers
        request.state.request_id = request_id
        
        try:
            # Process request
            response = await call_next(request)
            duration = time.time() - start_time
            
            # Log successful request
            logger.info(
                "HTTP request completed",
                extra={
                    "request_id": request_id,
                    "method": request.method,
                    "path": request.url.path,
                    "status_code": response.status_code,
                    "duration_seconds": round(duration, 3),
                    "client_ip": request.client.host if request.client else "unknown",
                }
            )
            
            return response
            
        except Exception as e:
            duration = time.time() - start_time
            logger.error(
                "HTTP request failed",
                extra={
                    "request_id": request_id,
                    "method": request.method,
                    "path": request.url.path,
                    "duration_seconds": round(duration, 3),
                    "error": str(e),
                    "error_type": type(e).__name__,
                },
                exc_info=True
            )
            raise


class ErrorHandlingMiddleware(BaseHTTPMiddleware):
    """
    Middleware for centralized error handling and response formatting
    """
    
    async def dispatch(self, request: Request, call_next) -> Response:
        try:
            response = await call_next(request)
            return response
        except ValueError as e:
            logger.warning(f"Validation error: {e}")
            return Response(
                content=f'{{"error": "Invalid request", "detail": "{str(e)}"}}',
                status_code=422,
                media_type="application/json"
            )
        except Exception as e:
            logger.error(f"Unhandled error: {e}", exc_info=True)
            return Response(
                content='{"error": "Internal server error"}',
                status_code=500,
                media_type="application/json"
            )


class HeaderLoggingMiddleware(BaseHTTPMiddleware):
    """
    Middleware for logging request headers (for debugging)
    Only logs in DEBUG mode
    """
    
    def __init__(self, app, debug: bool = False):
        super().__init__(app)
        self.debug = debug
    
    async def dispatch(self, request: Request, call_next) -> Response:
        if self.debug:
            logger.debug(
                "Request headers",
                extra={
                    "headers": dict(request.headers),
                    "path": request.url.path,
                }
            )
        
        response = await call_next(request)
        return response
