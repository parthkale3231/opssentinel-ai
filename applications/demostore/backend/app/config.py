
from __future__ import annotations

from pydantic import Field
from pydantic_settings import BaseSettings
from sqlalchemy.engine import URL


class Settings(BaseSettings):
    app_name: str = Field(default="demostore", alias="APP_NAME")
    app_version: str = Field(default="1.0.0", alias="APP_VERSION")
    environment: str = Field(default="local", alias="ENVIRONMENT")
    log_level: str = Field(default="INFO", alias="LOG_LEVEL")

    database_url: str = Field(
        default="postgresql+psycopg2://demostore:demostore@localhost:5432/demostore",
        alias="DATABASE_URL",
    )

    db_host: str | None = Field(default=None, alias="DB_HOST")
    db_port: int = Field(default=5432, alias="DB_PORT")
    db_name: str | None = Field(default=None, alias="DB_NAME")
    db_user: str | None = Field(default=None, alias="DB_USER")
    db_password: str | None = Field(default=None, alias="DB_PASSWORD")

    correlation_id_header: str = Field(
        default="X-Correlation-ID",
        alias="CORRELATION_ID_HEADER",
    )

    @property
    def sqlalchemy_database_url(self) -> str:
        if all([
            self.db_host,
            self.db_name,
            self.db_user,
            self.db_password is not None,
        ]):
            return URL.create(
                drivername="postgresql+psycopg2",
                username=self.db_user,
                password=self.db_password,
                host=self.db_host,
                port=self.db_port,
                database=self.db_name,
            ).render_as_string(hide_password=False)

        return self.database_url

    class Config:
        env_file = ".env"
        case_sensitive = False
        extra = "ignore"


settings = Settings()
