from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, scoped_session, sessionmaker, Session
from contextlib import contextmanager

# Create a base for SQLAlchemy mappers.
Base = declarative_base()
metadata = Base.metadata


# A Pydantic model to get environment variables.
class DbSettings(BaseSettings):
    """Settings for SQL."""

    host: str = Field(default="localhost", validation_alias="DB_HOST")
    user: str = Field(default="root", validation_alias="DB_USER")
    password: SecretStr = Field(default="", validation_alias="DB_PASSWORD")
    port: int = Field(default=3306, validation_alias="DB_PORT")
    db_name: str = Field(default="app", validation_alias="DB_NAME")
    connection_type: str = Field(default="direct", validation_alias="DB_CONNECTION_TYPE")
    
    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "extra": "ignore",
        "case_sensitive": True,
        "validate_default": False
    }

# Lazy initialization - only create when accessed
_db_settings = None

def get_db_settings():
    """Get or create DbSettings instance."""
    global _db_settings
    if _db_settings is None:
        _db_settings = DbSettings()
    return _db_settings

db_settings = get_db_settings()

db_conn_url = (
    "mysql+pymysql://"
    f"{db_settings.user}:{db_settings.password.get_secret_value()}"
    f"@{db_settings.host}:{db_settings.port}/{db_settings.db_name}"
    "?charset=utf8mb4"
)

# Configure connection args based on connection type
connect_args = {}
if db_settings.connection_type == "direct":
    # Direct connection to public IP with SSL
    # For MySQL 8.0+ caching_sha2_password authentication
    connect_args = {}
elif db_settings.connection_type == "proxy":
    # Cloud SQL Proxy connection (no SSL needed, proxy handles it)
    connect_args = {}

# Create SQLAlchemy SQL engine and session factory.
engine = create_engine(
    db_conn_url,
    connect_args=connect_args,
    pool_pre_ping=True,
    pool_recycle=3600,
    echo=True
)
session_factory = sessionmaker(bind=engine)
scoped_session_factory = scoped_session(session_factory)


@contextmanager
def get_db_sess():
    """Get a SQLAlchemy ORM Session instance.

    Yields:
        A SQLAlchemy ORM Session instance.
    """
    db_session: Session = scoped_session_factory()
    try:
        yield db_session
        db_session.commit()
    except Exception as exc:
        db_session.rollback()
        raise exc
    finally:
        db_session.close()