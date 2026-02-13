from fastapi import FastAPI
from sqlalchemy import text

from app.db.session import engine
from app.routers import auth

app = FastAPI()


@app.get("/health")
def health():
    return {"backend": "ok"}


# 전체 상태 체크 (DB 포함)
@app.get("/health/full")
def health_full():
    status = {"backend": "ok"}

    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1 FROM DUAL"))
        status["database"] = "ok"
    except Exception as e:
        status["database"] = "error"
        status["detail"] = str(e)

    return status

app.include_router(auth.router)
