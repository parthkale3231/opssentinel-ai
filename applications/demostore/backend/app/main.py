from __future__ import annotations

import time
from typing import Any

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse, Response

from app.api.routes.health import router as health_router
from app.api.routes.orders import router as orders_router
from app.api.routes.products import router as products_router
from app.config import settings
from app.database import run_migrations
from app.monitoring.metrics import HTTP_ERROR_COUNT, HTTP_REQUEST_COUNT, HTTP_REQUEST_LATENCY, metrics_payload

app = FastAPI(
    title=settings.app_name.title(),
    version=settings.app_version,
    description="DemoStore API for OpsSentinel AI demonstration and incident simulation.",
)

@app.on_event("startup")
def startup_event() -> None:
    run_migrations()


@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start = time.perf_counter()
    response = await call_next(request)
    duration = time.perf_counter() - start

    HTTP_REQUEST_COUNT.labels(request.method, request.url.path, response.status_code).inc()
    HTTP_REQUEST_LATENCY.labels(request.method, request.url.path).observe(duration)

    if response.status_code >= 400:
        HTTP_ERROR_COUNT.labels("http_error").inc()

    return response


@app.get("/", tags=["root"])
def read_root() -> dict[str, Any]:
    return {
        "message": "OpsSentinel AI DemoStore API is running.",
        "app": settings.app_name,
        "environment": settings.environment,
    }


@app.get("/metrics")
def metrics() -> Response:
    return Response(content=metrics_payload(), media_type="text/plain; version=0.7.0; charset=utf-8")


app.include_router(health_router, tags=["health"])
app.include_router(products_router, prefix="/api/products", tags=["products"])
app.include_router(orders_router, prefix="/api/orders", tags=["orders"])


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    return JSONResponse(status_code=500, content={"detail": "Internal server error"})
