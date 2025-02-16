from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import logging
import os
from contextlib import asynccontextmanager
from starlette.concurrency import run_in_threadpool
from .model import DialoGPTModel

# Initialize model
model = DialoGPTModel()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: load the model
    model.load()
    yield
    # Shutdown: any cleanup if needed

app = FastAPI(title="DialoGPT Chat API", lifespan=lifespan)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("ALLOWED_ORIGINS", "*").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ChatRequest(BaseModel):
    inputs: str = Field(..., max_length=2048)

@app.get("/")
async def start():
    return {"Running": "Ok"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.post("/chat")
async def chat(request: ChatRequest):
    try:
        logging.info("Received /chat request. Starting inference...")
        # Offload heavy computation to a background thread
        response = await run_in_threadpool(model.generate, request.inputs)
        logging.info("Inference completed.")
        return {"response": response}
    except Exception as e:
        logging.error(f"Error generating response: {e}")
        raise HTTPException(status_code=500, detail="Model inference failed")
