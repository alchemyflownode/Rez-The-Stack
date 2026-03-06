"""
SQLAlchemy models for database persistence
"""
from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, Text, Float, Index
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()


class User(Base):
    """User sessions"""
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(String(255), unique=True, index=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    last_activity = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f"<User session_id={self.session_id}>"


class ChatMessage(Base):
    """Chat messages storage"""
    __tablename__ = "chat_messages"
    
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(String(255), index=True, nullable=False)
    role = Column(String(50), nullable=False)  # "user" or "ai"
    content = Column(Text, nullable=False)
    worker = Column(String(50), nullable=False)  # brain, code, search, files
    model = Column(String(100))
    tokens_used = Column(Integer, default=0)
    processing_time_ms = Column(Float)  # milliseconds
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    
    # Create composite index for common queries
    __table_args__ = (
        Index('idx_session_created', 'session_id', 'created_at'),
    )
    
    def __repr__(self):
        return f"<ChatMessage id={self.id} role={self.role} worker={self.worker}>"


class WorkerLog(Base):
    """Worker execution logs for monitoring"""
    __tablename__ = "worker_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    worker = Column(String(50), index=True, nullable=False)
    status = Column(String(20), nullable=False)  # success, failed, timeout
    error = Column(Text)
    processing_time_ms = Column(Float)
    input_length = Column(Integer)
    output_length = Column(Integer)
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    
    def __repr__(self):
        return f"<WorkerLog worker={self.worker} status={self.status}>"


class HealthCheck(Base):
    """Health check history"""
    __tablename__ = "health_checks"
    
    id = Column(Integer, primary_key=True, index=True)
    service = Column(String(50), index=True, nullable=False)  # ollama, postgres, etc
    status = Column(String(20), nullable=False)  # healthy, unhealthy
    response_time_ms = Column(Float)
    error_message = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    
    def __repr__(self):
        return f"<HealthCheck service={self.service} status={self.status}>"
