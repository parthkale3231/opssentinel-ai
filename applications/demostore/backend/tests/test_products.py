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


def test_root_endpoint():
    reset_db()
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["app"] == "demostore"


def test_create_and_list_products():
    reset_db()
    payload = {
        "name": "Laptop",
        "description": "Gaming laptop",
        "price": 1299.99,
        "stock": 12,
    }
    response = client.post("/api/products/", json=payload)
    assert response.status_code == 201
    product_id = response.json()["id"]

    response = client.get("/api/products/")
    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["id"] == product_id


def test_update_and_delete_product():
    reset_db()
    payload = {
        "name": "Mouse",
        "description": "Wireless mouse",
        "price": 49.99,
        "stock": 18,
    }
    product = client.post("/api/products/", json=payload).json()
    update = {
        "name": "Mouse Pro",
        "description": "Ergonomic wireless mouse",
        "price": 59.99,
        "stock": 10,
    }

    response = client.put(f"/api/products/{product['id']}", json=update)
    assert response.status_code == 200
    assert response.json()["name"] == "Mouse Pro"

    response = client.delete(f"/api/products/{product['id']}")
    assert response.status_code == 204
