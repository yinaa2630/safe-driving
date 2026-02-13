from sqlalchemy import String, TIMESTAMP, func
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime
from app.db.base import Base


class User(Base):
    __tablename__ = "USERS"

    id: Mapped[int] = mapped_column(primary_key=True)

    email: Mapped[str] = mapped_column(
        "EMAIL",
        String(100),
        unique=True,
        nullable=False
    )

    password_hash: Mapped[str] = mapped_column(
        "PASSWORD",
        String(255),
        nullable=False
    )

    name: Mapped[str] = mapped_column(
        "NAME",
        String(50),
        nullable=False
    )

    created_at: Mapped[datetime] = mapped_column(
    "CREATED_AT",
    TIMESTAMP,
    nullable=False,
    server_default=func.current_timestamp(),
    insert_default=func.current_timestamp()
    )
