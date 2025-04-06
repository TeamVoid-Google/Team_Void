from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, status
from sqlalchemy.orm import Session
from typing import List, Optional
import os

from data.db_config import get_db
from ..services.community_services import CommunityService
from .schemas.community_schemas import (
    UserCreate, UserUpdate, UserResponse, UserDetailResponse,
    PostCreate, PostResponse, FeedResponse,
    CommentCreate, CommentResponse,
    ReplyCreate, ReplyResponse
)
from config.settings import MEDIA_STORAGE_PATH, MAX_IMAGE_SIZE_MB, ALLOWED_IMAGE_EXTENSIONS, POSTS_PER_PAGE


async def get_current_user_id():
    return 1  

router = APIRouter(prefix="/api/community", tags=["community"])

# User routes
@router.post("/users", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    user: UserCreate,
    db: Session = Depends(get_db)
):
    community_service = CommunityService(db)
    return community_service.create_user(
        username=user.username,
        handle=user.handle,
        bio=user.bio
    )

@router.get("/users/{user_id}", response_model=UserDetailResponse)
async def get_user(
    user_id: int,
    db: Session = Depends(get_db)
):
    community_service = CommunityService(db)
    user = community_service.get_user(user_id)
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    followers = community_service.get_followers(user_id)
    following = community_service.get_following(user_id)
    posts = community_service.get_user_posts(user_id)
    
    response = user.__dict__.copy()
    response["followers_count"] = len(followers)
    response["following_count"] = len(following)
    response["posts_count"] = len(posts)
    
    return response

@router.put("/users/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int,
    user_data: UserUpdate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    if user_id != current_user_id:
        raise HTTPException(status_code=403, detail="Not authorized to update this user")
    
    community_service = CommunityService(db)
    return community_service.update_user(user_id, user_data.dict(exclude_unset=True))

@router.post("/users/{user_id}/profile-image")
async def upload_profile_image(
    user_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    if user_id != current_user_id:
        raise HTTPException(status_code=403, detail="Not authorized to update this user")
    
    # Validate file size
    file_size = await file.read()
    await file.seek(0)  
    
    if len(file_size) > MAX_IMAGE_SIZE_MB * 1024 * 1024:
        raise HTTPException(
            status_code=400, 
            detail=f"File size exceeds the {MAX_IMAGE_SIZE_MB}MB limit"
        )
    
    # Validate file extension
    file_ext = file.filename.split(".")[-1].lower()
    if file_ext not in ALLOWED_IMAGE_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"File extension must be one of: {', '.join(ALLOWED_IMAGE_EXTENSIONS)}"
        )
    
    community_service = CommunityService(db)
    file_path = community_service.upload_profile_image(user_id, file)
    
    return {"file_path": file_path}

@router.post("/users/{user_id}/follow", status_code=status.HTTP_204_NO_CONTENT)
async def follow_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    if user_id == current_user_id:
        raise HTTPException(status_code=400, detail="Users cannot follow themselves")
    
    community_service = CommunityService(db)
    community_service.follow_user(current_user_id, user_id)
    return {"status": "success"}

@router.delete("/users/{user_id}/follow", status_code=status.HTTP_204_NO_CONTENT)
async def unfollow_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    community_service = CommunityService(db)
    community_service.unfollow_user(current_user_id, user_id)
    return {"status": "success"}

@router.get("/users/{user_id}/followers", response_model=List[UserResponse])
async def get_user_followers(
    user_id: int,
    db: Session = Depends(get_db)
):
    community_service = CommunityService(db)
    return community_service.get_followers(user_id)

@router.get("/users/{user_id}/following", response_model=List[UserResponse])
async def get_user_following(
    user_id: int,
    db: Session = Depends(get_db)
):
    community_service = CommunityService(db)
    return community_service.get_following(user_id)

@router.get("/users/search", response_model=List[UserResponse])
async def search_users(
    query: str,
    limit: int = 10,
    db: Session = Depends(get_db)
):
    community_service = CommunityService(db)
    return community_service.search_users(query, limit)

# Post routes
@router.post("/posts", response_model=PostResponse, status_code=status.HTTP_201_CREATED)
async def create_post(
    content: str = Form(...),
    image: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    # Validate image if provided
    if image:
        # Validate file size
        file_size = await image.read()
        await image.seek(0)  
        
        if len(file_size) > MAX_IMAGE_SIZE_MB * 1024 * 1024:
            raise HTTPException(
                status_code=400, 
                detail=f"File size exceeds the {MAX_IMAGE_SIZE_MB}MB limit"
            )
        
        # Validate file extension
        file_ext = image.filename.split(".")[-1].lower()
        if file_ext not in ALLOWED_IMAGE_EXTENSIONS:
            raise HTTPException(
                status_code=400,
                detail=f"File extension must be one of: {', '.join(ALLOWED_IMAGE_EXTENSIONS)}"
            )
    
    community_service = CommunityService(db)
    post = community_service.create_post(current_user_id, content, image)
    
    post_dict = post.__dict__.copy()
    post_dict["user"] = community_service.get_user(current_user_id)
    post_dict["likes_count"] = len(post.liked_by)
    post_dict["comments_count"] = len(post.comments)
    post_dict["is_liked"] = False
    post_dict["is_bookmarked"] = False
    
    return post_dict

@router.get("/posts/{post_id}", response_model=PostResponse)
async def get_post(
    post_id: int,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    community_service = CommunityService(db)
    post = community_service.get_post(post_id)
    
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    post_dict = post.__dict__.copy()
    post_dict["user"] = community_service.get_user(post.user_id)
    post_dict["likes_count"] = len(post.liked_by)
    post_dict["comments_count"] = len(post.comments)
    post_dict["is_liked"] = current_user_id in [user.id for user in post.liked_by]
    post_dict["is_bookmarked"] = current_user_id in [user.id for user in post.bookmarked_by]
    
    return post_dict

@router.get("/feed", response_model=FeedResponse)
async def get_feed(
    page: int = 1,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    if page < 1:
        page = 1
    
    community_service = CommunityService(db)
    posts = community_service.get_feed_posts(current_user_id, page, POSTS_PER_PAGE)
    
    more_posts = community_service.get_feed_posts(current_user_id, page + 1, 1)
    next_page = page + 1 if more_posts else None
    
    post_responses = []
    for post in posts:
        post_dict = post.__dict__.copy()
        post_dict["user"] = community_service.get_user(post.user_id)
        post_dict["likes_count"] = len(post.liked_by)
        post_dict["comments_count"] = len(post.comments)
        post_dict["is_liked"] = current_user_id in [user.id for user in post.liked_by]
        post_dict["is_bookmarked"] = current_user_id in [user.id for user in post.bookmarked_by]
        post_responses.append(post_dict)
    
    return {"posts": post_responses, "next_page": next_page}

@router.get("/discover", response_model=FeedResponse)
async def get_discover_feed(
    page: int = 1,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    if page < 1:
        page = 1
    
    community_service = CommunityService(db)
    posts = community_service.get_for_you_posts(page, POSTS_PER_PAGE)
    
    more_posts = community_service.get_for_you_posts(page + 1, 1)
    next_page = page + 1 if more_posts else None
    
    post_responses = []
    for post in posts:
        post_dict = post.__dict__.copy()
        post_dict["user"] = community_service.get_user(post.user_id)
        post_dict["likes_count"] = len(post.liked_by)
        post_dict["comments_count"] = len(post.comments)
        post_dict["is_liked"] = current_user_id in [user.id for user in post.liked_by]
        post_dict["is_bookmarked"] = current_user_id in [user.id for user in post.bookmarked_by]
        post_responses.append(post_dict)
    
    return {"posts": post_responses, "next_page": next_page}

@router.post("/posts/{post_id}/like", status_code=status.HTTP_204_NO_CONTENT)
async def like_post(
    post_id: int,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    community_service = CommunityService(db)
    community_service.like_post(current_user_id, post_id)
    return {"status": "success"}

@router.delete("/posts/{post_id}/like", status_code=status.HTTP_204_NO_CONTENT)
async def unlike_post(
    post_id: int,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    community_service = CommunityService(db)
    community_service.unlike_post(current_user_id, post_id)
    return {"status": "success"}

@router.post("/posts/{post_id}/bookmark", status_code=status.HTTP_204_NO_CONTENT)
async def bookmark_post(
    post_id: int,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    community_service = CommunityService(db)
    community_service.bookmark_post(current_user_id, post_id)
    return {"status": "success"}

@router.delete("/posts/{post_id}/bookmark", status_code=status.HTTP_204_NO_CONTENT)
async def remove_bookmark(
    post_id: int,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    community_service = CommunityService(db)
    community_service.remove_bookmark(current_user_id, post_id)
    return {"status": "success"}

@router.get("/bookmarks", response_model=FeedResponse)
async def get_bookmarked_posts(
    page: int = 1,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    if page < 1:
        page = 1
    
    community_service = CommunityService(db)
    posts = community_service.get_bookmarked_posts(current_user_id, page, POSTS_PER_PAGE)
    
    more_posts = community_service.get_bookmarked_posts(current_user_id, page + 1, 1)
    next_page = page + 1 if more_posts else None
    
    post_responses = []
    for post in posts:
        post_dict = post.__dict__.copy()
        post_dict["user"] = community_service.get_user(post.user_id)
        post_dict["likes_count"] = len(post.liked_by)
        post_dict["comments_count"] = len(post.comments)
        post_dict["is_liked"] = current_user_id in [user.id for user in post.liked_by]
        post_dict["is_bookmarked"] = True  
        post_responses.append(post_dict)
    
    return {"posts": post_responses, "next_page": next_page}

# Comment routes
@router.post("/comments", response_model=CommentResponse, status_code=status.HTTP_201_CREATED)
async def create_comment(
    comment: CommentCreate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    community_service = CommunityService(db)
    
    # Verify post exists
    post = community_service.get_post(comment.post_id)
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    comment_obj = community_service.create_comment(current_user_id, comment.post_id, comment.text)
    
    comment_dict = comment_obj.__dict__.copy()
    comment_dict["user"] = community_service.get_user(current_user_id)
    comment_dict["likes_count"] = len(comment_obj.liked_by)
    comment_dict["replies_count"] = len(comment_obj.replies)
    comment_dict["is_liked"] = False
    
    return comment_dict

@router.get("/posts/{post_id}/comments", response_model=List[CommentResponse])
async def get_post_comments(
    post_id: int,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    community_service = CommunityService(db)
    
    # Verify post exists
    post = community_service.get_post(post_id)
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    comments = community_service.get_post_comments(post_id)
    
    comment_responses = []
    for comment in comments:
        comment_dict = comment.__dict__.copy()
        comment_dict["user"] = community_service.get_user(comment.user_id)
        comment_dict["likes_count"] = len(comment.liked_by)
        comment_dict["replies_count"] = len(comment.replies)
        comment_dict["is_liked"] = current_user_id in [user.id for user in comment.liked_by]
        comment_responses.append(comment_dict)
    
    return comment_responses

@router.post("/comments/{comment_id}/like", status_code=status.HTTP_204_NO_CONTENT)
async def like_comment(
    comment_id: int,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    community_service = CommunityService(db)
    community_service.like_comment(current_user_id, comment_id)
    return {"status": "success"}

@router.delete("/comments/{comment_id}/like", status_code=status.HTTP_204_NO_CONTENT)
async def unlike_comment(
    comment_id: int,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    community_service = CommunityService(db)
    community_service.unlike_comment(current_user_id, comment_id)
    return {"status": "success"}

# Reply routes
@router.post("/replies", response_model=ReplyResponse, status_code=status.HTTP_201_CREATED)
async def create_reply(
    reply: ReplyCreate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    community_service = CommunityService(db)
    reply_obj = community_service.create_reply(current_user_id, reply.comment_id, reply.text)
    
    reply_dict = reply_obj.__dict__.copy()
    reply_dict["user"] = community_service.get_user(current_user_id)
    
    return reply_dict

@router.get("/comments/{comment_id}/replies", response_model=List[ReplyResponse])
async def get_comment_replies(
    comment_id: int,
    db: Session = Depends(get_db)
):
    community_service = CommunityService(db)
    replies = community_service.get_comment_replies(comment_id)
    
    reply_responses = []
    for reply in replies:
        reply_dict = reply.__dict__.copy()
        reply_dict["user"] = community_service.get_user(reply.user_id)
        reply_responses.append(reply_dict)
    
    return reply_responses