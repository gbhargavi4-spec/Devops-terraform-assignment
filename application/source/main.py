import os
import time
import asyncio

from fastapi import FastAPI, Response
from fastapi.responses import JSONResponse
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

app = FastAPI(title="devops-app", version="1.0.0")

REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"],
)
REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["endpoint"],
)

_db_engine = None


def _db_url() -> str:
    host = os.environ["DATABASE_HOST"]
    port = os.environ.get("DATABASE_PORT", "5432")
    name = os.environ["DATABASE_NAME"]
    user = os.environ["DATABASE_USER"]
    password = os.environ["DATABASE_PASSWORD"]
    return f"postgresql+asyncpg://{user}:{password}@{host}:{port}/{name}"


@app.on_event("startup")
async def startup():
    global _db_engine
    _db_engine = create_async_engine(_db_url(), pool_size=5, max_overflow=10)


@app.on_event("shutdown")
async def shutdown():
    if _db_engine:
        await _db_engine.dispose()


@app.get("/health")
async def health():
    REQUEST_COUNT.labels(method="GET", endpoint="/health", status="200").inc()
    return {"status": "ok"}


@app.get("/ready")
async def ready():
    start = time.monotonic()
    db_ok = False
    try:
        async with _db_engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        db_ok = True
    except Exception:
        pass

    latency = time.monotonic() - start
    REQUEST_LATENCY.labels(endpoint="/ready").observe(latency)

    status_code = 200 if db_ok else 503
    REQUEST_COUNT.labels(method="GET", endpoint="/ready", status=str(status_code)).inc()
    return JSONResponse(
        content={"status": "ready" if db_ok else "unavailable", "database": db_ok},
        status_code=status_code,
    )


@app.get("/api/v1/status")
async def status():
    start = time.monotonic()
    db_ok = False
    db_latency_ms = None
    try:
        t0 = time.monotonic()
        async with _db_engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        db_latency_ms = round((time.monotonic() - t0) * 1000, 2)
        db_ok = True
    except Exception as exc:
        db_latency_ms = None

    REQUEST_LATENCY.labels(endpoint="/api/v1/status").observe(time.monotonic() - start)
    REQUEST_COUNT.labels(method="GET", endpoint="/api/v1/status", status="200").inc()

    return {
        "environment": os.environ.get("ENVIRONMENT", "unknown"),
        "project": os.environ.get("PROJECT", "unknown"),
        "database": {
            "connected": db_ok,
            "latency_ms": db_latency_ms,
        },
    }


@app.get("/metrics")
async def metrics():
    REQUEST_COUNT.labels(method="GET", endpoint="/metrics", status="200").inc()
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)
