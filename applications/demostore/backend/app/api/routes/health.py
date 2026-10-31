
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db, healthcheck_db

router = APIRouter()


@router.get("/health")
def health_check() -> dict[str, str]:
    return {
        "status": "ok",
        "service": settings.app_name,
        "environment": settings.environment,
    }


@router.get("/ready")
def readiness_check(
    db: Session = Depends(get_db),
) -> dict[str, str | bool]:
    db_ok = healthcheck_db(db)

    if not db_ok:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "status": "degraded",
                "database": False,
                "service": settings.app_name,
            },
        )

    return {
        "status": "ok",
        "database": True,
        "service": settings.app_name,
    }
