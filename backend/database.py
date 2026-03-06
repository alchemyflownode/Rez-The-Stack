"""
Database connection and session management
Handles async database operations with connection pooling
"""
import logging
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.pool import QueuePool, StaticPool
from models import Base

logger = logging.getLogger(__name__)

# Database URL - Use PostgreSQL in production
# For development with SQLite: "sqlite+aiosqlite:///./rez_hive.db"
DATABASE_URL = "sqlite+aiosqlite:///./rez_hive.db"

# Create async engine with connection pooling
engine_kwargs = {
    "echo": False,  # Set to True for SQL debugging
    "poolclass": StaticPool if "sqlite" in DATABASE_URL else QueuePool,
    "pool_pre_ping": True,  # Test connection before using
}

# Only add pool parameters for non-SQLite databases
if "sqlite" not in DATABASE_URL:
    engine_kwargs["pool_size"] = 20  # Max 20 connections
    engine_kwargs["max_overflow"] = 10  # Allow 10 more temporary connections

# Add connect args
if "sqlite" in DATABASE_URL:
    engine_kwargs["connect_args"] = {
        "timeout": 30,  # Connection timeout
        "check_same_thread": False  # Required for SQLite
    }

engine = create_async_engine(DATABASE_URL, **engine_kwargs)

# Create async session maker
SessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,  # Keep objects loaded after commit
    autoflush=False,
)


async def init_db():
    """Initialize database tables"""
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        logger.info("✅ Database tables initialized")
    except Exception as e:
        logger.error(f"❌ Database initialization failed: {e}", exc_info=True)
        raise


async def close_db():
    """Close database connection pool"""
    try:
        await engine.dispose()
        logger.info("✅ Database connections closed")
    except Exception as e:
        logger.error(f"❌ Error closing database: {e}", exc_info=True)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    Dependency injection for database session.
    Usage: async def my_endpoint(db: AsyncSession = Depends(get_db)):
    """
    async with SessionLocal() as session:
        try:
            yield session
        except Exception as e:
            await session.rollback()
            logger.error(f"Database session error: {e}", exc_info=True)
            raise
        finally:
            await session.close()
