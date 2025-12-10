from sqlalchemy.orm import Session
from passlib.context import CryptContext
from database import engine, SessionLocal
from models import User, Base
import sys

# Create tables if they don't exist
Base.metadata.create_all(bind=engine)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def add_user(email: str, password: str):
    db = SessionLocal()
    try:
        existing_user = db.query(User).filter(User.email == email).first()
        if existing_user:
            print(f"❌ User with email {email} already exists!")
            return False
        
        hashed_password = pwd_context.hash(password)
        
        user = User(
            email=email,
            password=hashed_password,
            timeout=0
        )
        
        db.add(user)
        db.commit()
        db.refresh(user)
        
        print(f"✅ User created successfully!")
        print(f"   ID: {user.id}")
        print(f"   Email: {user.email}")
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
        return False
    finally:
        db.close()

def list_users():
    db = SessionLocal()
    try:
        users = db.query(User).all()
        if not users:
            print("No users found in database.")
            return
        
        print(f"\n{'ID':<5} {'Email':<30} {'Created At':<20}")
        print("-" * 60)
        for user in users:
            print(f"{user.id:<5} {user.email:<30} {str(user.created_at):<20}")
    finally:
        db.close()

if __name__ == "__main__":
    print("=" * 60)
    print("User Management Script")
    print("=" * 60)
    
    while True:
        print("\n1. Add new user")
        print("2. List all users")
        print("3. Exit")
        
        choice = input("\nSelect option (1-3): ").strip()
        
        if choice == "1":
            email = input("Enter email: ").strip()
            password = input("Enter password: ").strip()
            
            if not email or not password:
                print("❌ Email and password cannot be empty!")
                continue
            
            add_user(email, password)
            
        elif choice == "2":
            list_users()
            
        elif choice == "3":
            print("Goodbye!")
            sys.exit(0)
        else:
            print("❌ Invalid option!")