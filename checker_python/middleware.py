from fastapi import Header, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from sqlalchemy.orm import Session
from datetime import datetime
import models
from database import get_db
from config import settings

security = HTTPBearer()

async def require_auth(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
):
    token = credentials.credentials
    
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: int = payload.get("foo")
        exp: float = payload.get("exp")
        
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid authentication credentials")
        
        if datetime.utcnow().timestamp() > exp:
            raise HTTPException(status_code=401, detail="Token has expired")
        
        user = db.query(models.User).filter(models.User.id == user_id).first()
        
        if user is None:
            raise HTTPException(status_code=401, detail="User not found")
        
        return user
        
    except JWTError:
        raise HTTPException(status_code=401, detail="Could not validate credentials")