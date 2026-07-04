import os
import random
import asyncio
import time
from datetime import datetime

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy import select

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+asyncpg://postgres:sua_senha@localhost:5432/seu_banco"
)

engine = create_async_engine(DATABASE_URL, echo=False)
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


class PaymentTransaction(Base):
    __tablename__ = "payment_transactions"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    amount: Mapped[float]
    status: Mapped[str]
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)


REQUESTS_TOTAL = Counter("payment_requests_total", "Total payment requests", ["status"])
LATENCY = Histogram("payment_latency_seconds", "Payment request latency", buckets=[.005, .01, .025, .05, .1, .25, .5, 1, 2.5])

app = FastAPI(title="Payment Gateway API")


class PaymentRequest(BaseModel):
    amount: float | None = None


@app.on_event("startup")
async def startup():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


@app.get("/metrics")
async def metrics():
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.post("/api/payments")
async def process_payment(request: PaymentRequest):
    start = time.monotonic()
    await asyncio.sleep(random.randint(20, 250) / 1000)

    chance = random.random()

    if chance < 0.05:
        REQUESTS_TOTAL.labels(status="500").inc()
        LATENCY.observe(time.monotonic() - start)
        raise HTTPException(500, "Timeout na comunicação com a Bandeira do Cartão")

    async with async_session() as session:
        if chance < 0.15:
            tx = PaymentTransaction(amount=request.amount or 0.0, status="DECLINED")
            session.add(tx)
            await session.commit()
            REQUESTS_TOTAL.labels(status="400").inc()
            LATENCY.observe(time.monotonic() - start)
            raise HTTPException(400, "Saldo insuficiente")

        tx = PaymentTransaction(amount=request.amount or 150.0, status="APPROVED")
        session.add(tx)
        await session.commit()
        REQUESTS_TOTAL.labels(status="200").inc()
        LATENCY.observe(time.monotonic() - start)
        return {
            "id": tx.id,
            "amount": tx.amount,
            "status": tx.status,
            "created_at": tx.created_at.isoformat(),
        }


@app.get("/api/payments")
async def get_all():
    async with async_session() as session:
        result = await session.execute(select(PaymentTransaction))
        txs = result.scalars().all()
        return [
            {
                "id": tx.id,
                "amount": tx.amount,
                "status": tx.status,
                "created_at": tx.created_at.isoformat(),
            }
            for tx in txs
        ]
