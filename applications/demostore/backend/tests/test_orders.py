from fastapi.testclient import TestClient

from app.database import SessionLocal, init_db
from app.main import app
from app.models.order import Order
from app.models.product import Product

client = TestClient(app)


def reset_db():
    init_db()
    db = SessionLocal()
    db.query(Order).delete()
    db.query(Product).delete()
    db.commit()
    db.close()


def test_create_order_and_read_it():
    reset_db()
    product_response = client.post(
        "/api/products/",
        json={
            "name": "Keyboard",
            "description": "Mechanical keyboard",
            "price": 89.5,
            "stock": 20,
        },
    )
    product_id = product_response.json()["id"]

    response = client.post(
        "/api/orders/",
        json={"product_id": product_id, "quantity": 2},
    )
    assert response.status_code == 201
    body = response.json()
    assert body["status"] == "pending"
    assert body["total_price"] == 179.0

    order = client.get(f"/api/orders/{body['id']}")
    assert order.status_code == 200
    assert order.json()["quantity"] == 2


def test_order_fails_when_stock_is_insufficient():
    reset_db()
    product = client.post(
        "/api/products/",
        json={
            "name": "Monitor",
            "description": "27-inch display",
            "price": 299.99,
            "stock": 1,
        },
    ).json()

    response = client.post(
        "/api/orders/",
        json={"product_id": product["id"], "quantity": 2},
    )
    assert response.status_code == 400
    assert "Insufficient" in response.json()["detail"]
