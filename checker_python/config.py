import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    SECRET_KEY = os.getenv("SECRET", "your-secret-key-here")
    BPATH = os.getenv("BPATH", "./uploads")
    DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./checker.db")
    
    # Queue settings
    QUEUE_SIZE = 10
    PARALLEL_CONTAINERS = 4
    TIMEOUT_UPLOAD = 60
    
    # JWT settings
    ALGORITHM = "HS256"
    ACCESS_TOKEN_EXPIRE_DAYS = 7

settings = Settings()