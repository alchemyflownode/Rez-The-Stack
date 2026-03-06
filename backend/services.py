"""
Business logic layer - Services for handling core operations
Separates business logic from API handlers
"""
import logging
from datetime import datetime
from typing import List, Dict, Any, Optional
from sqlalchemy import select, desc
from sqlalchemy.ext.asyncio import AsyncSession
from models import ChatMessage, User, WorkerLog, HealthCheck

logger = logging.getLogger(__name__)


class UserService:
    """Handle user session management"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def get_or_create_user(self, session_id: str) -> User:
        """Get existing user or create new one"""
        try:
            # Check if user exists
            stmt = select(User).where(User.session_id == session_id)
            result = await self.db.execute(stmt)
            user = result.scalars().first()
            
            if user:
                # Update last activity
                user.last_activity = datetime.utcnow()
                await self.db.commit()
                return user
            
            # Create new user
            user = User(session_id=session_id)
            self.db.add(user)
            await self.db.commit()
            logger.info(f"Created new user session: {session_id}")
            return user
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Error in get_or_create_user: {e}", exc_info=True)
            raise


class ChatService:
    """Handle chat message storage and retrieval"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def save_message(
        self,
        session_id: str,
        role: str,
        content: str,
        worker: str,
        model: Optional[str] = None,
        tokens_used: int = 0,
        processing_time_ms: Optional[float] = None
    ) -> ChatMessage:
        """Save a chat message to database"""
        try:
            message = ChatMessage(
                session_id=session_id,
                role=role,
                content=content,
                worker=worker,
                model=model,
                tokens_used=tokens_used,
                processing_time_ms=processing_time_ms,
            )
            self.db.add(message)
            await self.db.commit()
            logger.info(
                f"Saved message",
                extra={
                    "session_id": session_id,
                    "role": role,
                    "worker": worker,
                    "content_length": len(content),
                }
            )
            return message
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Error saving message: {e}", exc_info=True)
            raise
    
    async def get_chat_history(
        self,
        session_id: str,
        limit: int = 50,
        offset: int = 0
    ) -> List[ChatMessage]:
        """Retrieve chat history for a session"""
        try:
            stmt = (
                select(ChatMessage)
                .where(ChatMessage.session_id == session_id)
                .order_by(desc(ChatMessage.created_at))
                .limit(limit)
                .offset(offset)
            )
            result = await self.db.execute(stmt)
            messages = result.scalars().all()
            # Reverse to get chronological order
            return list(reversed(messages))
        except Exception as e:
            logger.error(f"Error retrieving chat history: {e}", exc_info=True)
            raise
    
    async def clear_session_chat(self, session_id: str) -> int:
        """Delete all messages for a session"""
        try:
            stmt = select(ChatMessage).where(ChatMessage.session_id == session_id)
            result = await self.db.execute(stmt)
            messages = result.scalars().all()
            
            for msg in messages:
                await self.db.delete(msg)
            
            await self.db.commit()
            logger.info(f"Cleared {len(messages)} messages for session: {session_id}")
            return len(messages)
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Error clearing chat: {e}", exc_info=True)
            raise


class WorkerLogService:
    """Handle worker execution logging"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def log_execution(
        self,
        worker: str,
        status: str,
        processing_time_ms: float,
        input_length: int = 0,
        output_length: int = 0,
        error: Optional[str] = None
    ) -> WorkerLog:
        """Log worker execution for monitoring"""
        try:
            log = WorkerLog(
                worker=worker,
                status=status,
                processing_time_ms=processing_time_ms,
                input_length=input_length,
                output_length=output_length,
                error=error,
            )
            self.db.add(log)
            await self.db.commit()
            logger.info(
                f"Worker execution logged",
                extra={
                    "worker": worker,
                    "status": status,
                    "processing_time_ms": processing_time_ms,
                }
            )
            return log
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Error logging worker execution: {e}", exc_info=True)
            raise
    
    async def get_worker_stats(
        self,
        worker: str,
        hours: int = 24
    ) -> Dict[str, Any]:
        """Get worker statistics"""
        try:
            from datetime import timedelta
            from sqlalchemy import func
            
            cutoff = datetime.utcnow() - timedelta(hours=hours)
            stmt = select(WorkerLog).where(
                (WorkerLog.worker == worker) &
                (WorkerLog.created_at >= cutoff)
            )
            
            result = await self.db.execute(stmt)
            logs = result.scalars().all()
            
            if not logs:
                return {
                    "worker": worker,
                    "total_executions": 0,
                    "success_rate": 0,
                    "avg_time_ms": 0,
                }
            
            success_count = sum(1 for log in logs if log.status == "success")
            total_time = sum(log.processing_time_ms for log in logs if log.processing_time_ms)
            
            return {
                "worker": worker,
                "total_executions": len(logs),
                "success_count": success_count,
                "success_rate": success_count / len(logs) * 100,
                "avg_time_ms": total_time / len(logs) if logs else 0,
                "failures": [log.error for log in logs if log.status == "failed"],
            }
        except Exception as e:
            logger.error(f"Error getting worker stats: {e}", exc_info=True)
            raise


class HealthCheckService:
    """Handle health check logging"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def log_health_check(
        self,
        service: str,
        status: str,
        response_time_ms: Optional[float] = None,
        error_message: Optional[str] = None
    ) -> HealthCheck:
        """Log service health check result"""
        try:
            check = HealthCheck(
                service=service,
                status=status,
                response_time_ms=response_time_ms,
                error_message=error_message,
            )
            self.db.add(check)
            await self.db.commit()
            return check
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Error logging health check: {e}", exc_info=True)
            raise
    
    async def get_latest_health(self, service: str) -> Optional[HealthCheck]:
        """Get latest health check for a service"""
        try:
            stmt = (
                select(HealthCheck)
                .where(HealthCheck.service == service)
                .order_by(desc(HealthCheck.created_at))
                .limit(1)
            )
            result = await self.db.execute(stmt)
            return result.scalars().first()
        except Exception as e:
            logger.error(f"Error getting health check: {e}", exc_info=True)
            raise
