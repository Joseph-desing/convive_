from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

import backend.main as ai_backend
import chatbot_backend_mock as guided_backend


@asynccontextmanager
async def lifespan(app: FastAPI):
    ai_backend.client = httpx.AsyncClient(timeout=30.0)
    yield
    await ai_backend.client.aclose()


app = FastAPI(
    title="ConVive Combined Backend",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    return {
        "status": "ok",
        "service": "ConVive Combined Backend",
        "docs": "/docs",
        "health": "/health",
    }


for route in ai_backend.app.router.routes:
    if route.path in {"/", "/docs", "/redoc", "/openapi.json"}:
        continue
    app.router.routes.append(route)

for route in guided_backend.app.router.routes:
    if route.path in {"/", "/docs", "/redoc", "/openapi.json", "/health"}:
        continue
    app.router.routes.append(route)
