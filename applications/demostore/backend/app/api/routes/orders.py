from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.order import Order
from app.models.product import Product
from app.schemas.order import OrderCreate, OrderRead

router = APIRouter()


@router.get("/", response_model=list[OrderRead])
def list_orders(
    skip: Annotated[int, Query(ge=0)] = 0,
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
    db: Session = Depends(get_db),
):
    return db.query(Order).order_by(Order.created_at.desc()).offset(skip).limit(limit).all()


@router.post("/", response_model=OrderRead, status_code=status.HTTP_201_CREATED)
def create_order(order: OrderCreate, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == order.product_id).first()
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found.")

    if product.stock < order.quantity:
        raise HTTPException(status_code=400, detail="Insufficient product stock.")

    total = product.price * order.quantity
    db_order = Order(
        product_id=order.product_id,
        quantity=order.quantity,
        status="pending",
        total_price=total,
    )

    product.stock -= order.quantity
    db.add(db_order)
    db.commit()
    db.refresh(db_order)
    db.refresh(product)
    return db_order


@router.get("/{order_id}", response_model=OrderRead)
def read_order(order_id: int, db: Session = Depends(get_db)):
    order = db.query(Order).filter(Order.id == order_id).first()
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found.")
    return order
