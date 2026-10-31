from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_metrics_endpoint_returns_prometheus_data():
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "# HELP" in response.text
    assert "demostore_http_requests_total" in response.text
