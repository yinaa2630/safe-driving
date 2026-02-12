# Safe Driving Backend

## 도커 실행 방법

```bash
docker compose up --build
```

## 확인 방법
Backend health check:
http://localhost:8000/health
정상 실행 시 다음과 같은 응답이 반환됩니다:

```json
{"status": "ok"}
```
---

## 현재 구성
> FastAPI 기반 Backend
> Oracle XE (Docker 컨테이너)
> Docker Compose로 실행 환경 통합
