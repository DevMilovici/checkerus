import asyncio
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Depends, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

import controllers
from database import init_db, get_db
from middleware import require_auth

# Logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting application...")
    init_db()
    asyncio.create_task(controllers.process_queue_worker())
    logger.info("Application started!")
    yield
    logger.info("Shutting down...")

app = FastAPI(lifespan=lifespan, debug=True)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["Authorization", "Content-Type"],
    max_age=43200,
)

# Routes
@app.post("/signup")
async def signup_route(
    body: controllers.SignupRequest,
    db: Session = Depends(get_db)
):
    return await controllers.signup(body, db)

@app.post("/login")
async def login_route(
    body: controllers.LoginRequest,
    db: Session = Depends(get_db)
):
    return await controllers.login(body, db)

@app.get("/validate")
async def validate_route(user = Depends(require_auth)):
    return await controllers.validate(user)

@app.get("/logout")
async def logout_route(user = Depends(require_auth)):
    return await controllers.logout()

@app.post("/upload")
async def upload_route(
    file: UploadFile,
    user = Depends(require_auth),
    db: Session = Depends(get_db)
):
    return await controllers.upload_file(file, user, db)

@app.get("/canLoad")
async def can_upload_route(
    user = Depends(require_auth),
    db: Session = Depends(get_db)
):
    return await controllers.can_upload(user, db)

@app.get("/history")
async def history_route(
    user = Depends(require_auth),
    db: Session = Depends(get_db)
):
    return await controllers.get_user_uploads(user, db)

@app.get("/queue-status")
async def queue_status_route(user = Depends(require_auth)):
    return await controllers.queue_status(user)

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "queue_size": controllers.request_queue.qsize()
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="debug"
    )