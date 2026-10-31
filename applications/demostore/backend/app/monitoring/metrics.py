from __future__ import annotations

from prometheus_client import Counter, Histogram, generate_latest

HTTP_REQUEST_COUNT = Counter(
    "demostore_http_requests_total",
    "Total number of HTTP requests received by DemoStore.",
    labelnames=("method", "path", "status"),
)

HTTP_REQUEST_LATENCY = Histogram(
    "demostore_http_request_duration_seconds",
    "HTTP request latency in seconds.",
    labelnames=("method", "path"),
)

HTTP_ERROR_COUNT = Counter(
    "demostore_http_errors_total",
    "Total number of HTTP errors encountered.",
    labelnames=("type",),
)


def metrics_payload() -> bytes:
    return generate_latest()
