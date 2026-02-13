import os
from datetime import timedelta

SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM", "HS256")

ACCESS_TOKEN_EXPIRE = timedelta(
    hours=int(os.getenv("ACCESS_TOKEN_EXPIRE_HOURS", 24))
)
