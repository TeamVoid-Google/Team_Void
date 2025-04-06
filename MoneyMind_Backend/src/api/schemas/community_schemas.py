from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime

# User schemas
class UserBase(BaseModel):
    username: str
    handle: str
    bio: Optional[str] = None

class UserCreate(UserBase):
    pass

class UserUpdate(BaseModel):
    username: Optional[str] = None
    bio: Optional[str] = None

class UserFollow(BaseModel):
    user_id: int

class UserResponse(UserBase):
    id: int
    profile_image: Optional[str] = None
    
    class Config:
        orm_mode = True

class UserDetailResponse(UserResponse):
    followers_count: int
    following_count: int
    posts_count: int
    
    class Config:
        orm_mode = True

# Post schemas
class PostBase(BaseModel):
    content: str

class PostCreate(PostBase):
    pass

class PostResponse(PostBase):
    id: int
    user_id: int
    user: UserResponse
    has_image: bool
    image_url: Optional[str] = None
    created_at: datetime
    likes_count: int
    comments_count: int
    is_liked: bool
    is_bookmarked: bool
    
    class Config:
        orm_mode = True

# Comment schemas
class CommentBase(BaseModel):
    text: str

class CommentCreate(CommentBase):
    post_id: int

class CommentResponse(CommentBase):
    id: int
    post_id: int
    user_id: int
    user: UserResponse
    created_at: datetime
    likes_count: int
    replies_count: int
    is_liked: bool
    
    class Config:
        orm_mode = True

# Reply schemas
class ReplyBase(BaseModel):
    text: str

class ReplyCreate(ReplyBase):
    comment_id: int

class ReplyResponse(ReplyBase):
    id: int
    comment_id: int
    user_id: int
    user: UserResponse
    created_at: datetime
    
    class Config:
        orm_mode = True

# Feed schemas
class FeedResponse(BaseModel):
    posts: List[PostResponse]
    next_page: Optional[int] = None
    
    class Config:
        orm_mode = True