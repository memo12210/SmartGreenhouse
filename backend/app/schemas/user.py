import uuid
from typing import Optional
from pydantic import BaseModel, EmailStr, ConfigDict, Field
from app.domain.user import UserRole


class UserBase(BaseModel):
    email: EmailStr
    full_name: Optional[str] = None
    role: UserRole = UserRole.VIEWER
    is_active: bool = True


# Public self-registration. Deliberately does NOT expose role/is_active so that
# users cannot grant themselves privileges (mass-assignment / privilege escalation).
class UserRegister(BaseModel):
    email: EmailStr
    full_name: Optional[str] = None
    # bcrypt silently truncates at 72 bytes; enforce a sane policy.
    password: str = Field(min_length=12, max_length=72)


# Self-service profile update. No role/is_active for the same reason as UserRegister.
class UserSelfUpdate(BaseModel):
    email: Optional[EmailStr] = None
    full_name: Optional[str] = None
    password: Optional[str] = Field(default=None, min_length=12, max_length=72)


# Admin-only creation/update (role/is_active allowed). Must be guarded by an
# admin role dependency wherever it is used.
class UserCreate(UserBase):
    password: str = Field(min_length=12, max_length=72)


class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    full_name: Optional[str] = None
    password: Optional[str] = Field(default=None, min_length=12, max_length=72)
    role: Optional[UserRole] = None
    is_active: Optional[bool] = None


class UserRead(UserBase):
    id: uuid.UUID

    model_config = ConfigDict(from_attributes=True)


class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str


class TokenData(BaseModel):
    sub: Optional[str] = None
    type: Optional[str] = None
