import asyncio
import hashlib
import os
import re
import shutil
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional

from fastapi import HTTPException, UploadFile
from jose import jwt
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session

import models
from config import settings
from database import get_db

# Remove this line:
# from middleware import require_auth

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Queue and semaphore
request_queue: asyncio.Queue = asyncio.Queue(maxsize=settings.QUEUE_SIZE)
semaphore = asyncio.Semaphore(settings.PARALLEL_CONTAINERS)

# Pydantic models
class SignupRequest(BaseModel):
    email: EmailStr
    password: str

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class UploadRequest:
    def __init__(self, file: UploadFile, user_id: int, user_dir: str, filename: str):
        self.file = file
        self.user_id = user_id
        self.user_dir = user_dir
        self.filename = filename

# Helper functions
def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(user_id: int) -> str:
    expire = datetime.utcnow() + timedelta(days=settings.ACCESS_TOKEN_EXPIRE_DAYS)
    to_encode = {"foo": user_id, "exp": expire.timestamp()}
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

# Controllers - Notice: NO Depends() here, just plain parameters
async def signup(body: SignupRequest, db: Session):
    existing_user = db.query(models.User).filter(models.User.email == body.email).first()
    
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already in use")
    
    hashed_password = hash_password(body.password)
    user = models.User(email=body.email, password=hashed_password, timeout=0)
    
    db.add(user)
    db.commit()
    db.refresh(user)
    
    return {"status": "Signup OK!"}

async def login(body: LoginRequest, db: Session):
    user = db.query(models.User).filter(models.User.email == body.email).first()
    
    if not user or not verify_password(body.password, user.password):
        raise HTTPException(status_code=400, detail="Invalid email or password!")
    
    token = create_access_token(user.id)
    
    return {"token": token}

async def validate(user: models.User):
    return {"message": user.email}

async def logout():
    return {"message": "Logout successful!"}

async def can_upload(user: models.User, db: Session):
    db.refresh(user)
    wait_time = int(datetime.utcnow().timestamp()) - user.timeout
    
    if wait_time < settings.TIMEOUT_UPLOAD:
        return {"wait": settings.TIMEOUT_UPLOAD - wait_time}
    
    return {"wait": 0}
async def run_in_docker(filename: str, path: str) -> tuple[str, Optional[str]]:
    print(f"=" * 60)
    print(f"Running Docker with: {filename} in path: {path}")
    
    # Check if path exists
    if not os.path.exists(path):
        print(f"ERROR: Path does not exist: {path}")
        return "", f"Path does not exist: {path}"
    
    # List files in directory
    print(f"Files in {path}:")
    try:
        for f in os.listdir(path):
            file_path = os.path.join(path, f)
            size = os.path.getsize(file_path) if os.path.isfile(file_path) else "DIR"
            print(f"  - {f} ({size} bytes)")
    except Exception as e:
        print(f"ERROR listing files: {e}")
    
    # Check if file exists
    file_path = os.path.join(path, filename)
    if not os.path.exists(file_path):
        print(f"ERROR: File does not exist: {file_path}")
        return "", f"File does not exist: {filename}"
    
    print(f"File {filename} exists, size: {os.path.getsize(file_path)} bytes")
    
    # Docker command with extensive debugging
    cmd = [
    "docker", "run",
    "--stop-timeout", "100",
    "--network", "none",
    "--rm",
    "--cpus=8.0",
    "--memory=2g",
    "-v", f"{os.path.abspath(path)}:/workspace",
    "-w", "/workspace",
    "gcc-withbc",
    "bash", "-c",
    (
        "echo '=== Docker Container Started ===' && "
        "echo 'Copying scripts and test files...' && "
        "cp -v /app/scripts/* /workspace/ 2>&1 && "
        "cp -v /app/tests/* /workspace/ 2>&1 && "
        "chmod +x /workspace/*.sh && "
        "echo 'Files in workspace:' && ls -la /workspace/ && "
        "echo 'Running verify.sh...' && "
        f"./verify.sh {filename} 2>&1"
    )
]
    
    try:
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        
        
        try:
            stdout, stderr = await asyncio.wait_for(
                process.communicate(),
                timeout=120.0
            )
            
            stdout_str = stdout.decode('utf-8', errors='replace')
            stderr_str = stderr.decode('utf-8', errors='replace')
            
    
            
            output = stdout_str + stderr_str
            
            
            error = None if process.returncode == 0 else stderr_str
            
           
            return output, error
            
        except asyncio.TimeoutError:
            print(f"ERROR: Docker execution timed out!")
            try:
                process.kill()
                await process.wait()
            except:
                pass
            return "", "Docker execution timed out after 120 seconds"
        
    except Exception as e:
        print(f"ERROR: Exception during Docker execution: {e}")
        import traceback
        traceback.print_exc()
        return "", str(e)

async def process_queue_worker():
    print("Queue worker started")
    while True:
        try:
            req: UploadRequest = await request_queue.get()
            print(f"Processing: {req.filename}")
            
            async with semaphore:
                try:
                    output, err = await run_in_docker(req.filename, req.user_dir)
                    result = output if not err else err
                    
                    print("RESULT HERE!")
                    print(result)
                    if not result:
                        result = "Compilation error or no output!"
                    
                    match = re.search(r'Total points: (\d+)', result)
                    total_points = int(match.group(1)) if match else 0
                    
                    print(f"Result: {total_points} points")
                    
                    db = next(get_db())
                    try:
                        upload_record = models.UploadHistory(
                            user_id=req.user_id,
                            filename=req.filename,
                            result=result,
                            points=total_points
                        )
                        db.add(upload_record)
                        db.commit()
                    except Exception as db_err:
                        print(f"DB error: {db_err}")
                        db.rollback()
                    finally:
                        db.close()
                    
                except Exception as e:
                    print(f"Error processing upload: {e}")
                    import traceback
                    traceback.print_exc()
                finally:
                    request_queue.task_done()
        except Exception as e:
            print(f"Queue worker error: {e}")
            await asyncio.sleep(1)

def copy_files(src_dir: str, dest_dir: str):
    src_path = Path(src_dir)
    dest_path = Path(dest_dir)
    
    if not src_path.exists():
        raise FileNotFoundError(f"Source directory not found: {src_dir}")
    
    for file in src_path.iterdir():
        if file.is_file():
            shutil.copy2(file, dest_path / file.name)

async def upload_file(file: UploadFile, user: models.User, db: Session):
    wait_time = int(datetime.utcnow().timestamp()) - user.timeout
    
    if wait_time < settings.TIMEOUT_UPLOAD:
        return {"wait": settings.TIMEOUT_UPLOAD - wait_time}
    
    user.timeout = int(datetime.utcnow().timestamp())
    db.commit()
    
    username_for_dir = user.email.split("@")[0]
    user_dir = Path(settings.BPATH) / username_for_dir
    user_dir.mkdir(parents=True, exist_ok=True)
    
    hash_input = str(datetime.utcnow().timestamp()).encode()
    hash_string = hashlib.md5(hash_input).hexdigest()
    timestamp = datetime.now().strftime("%d.%m-%H_%M")
    new_filename = f"{hash_string}_{timestamp}.c"
    file_path = user_dir / new_filename
    
    content = await file.read()
    with open(file_path, "wb") as f:
        f.write(content)
    
    # Scripts are in Docker image, no need to copy
    # scripts_dir = Path(settings.BPATH) / "scripts"
    # copy_files(str(scripts_dir), str(user_dir))
    
    req = UploadRequest(file, user.id, str(user_dir), new_filename)
    
    try:
        request_queue.put_nowait(req)
        return {"status": "success"}
    except asyncio.QueueFull:
        raise HTTPException(status_code=503, detail="Queue is full")

async def get_user_uploads(user: models.User, db: Session):
    uploads = db.query(
        models.UploadHistory.id,
        models.UploadHistory.timestamp,
        models.UploadHistory.result,
        models.UploadHistory.points
    ).filter(models.UploadHistory.user_id == user.id).all()
    
    return {"uploads": [
        {
            "Id": u.id,
            "Timestamp": u.timestamp,
            "Result": u.result,
            "Points": u.points
        } for u in uploads
    ]}

async def queue_status(user: models.User):
    return {"queue-status": request_queue.qsize()}