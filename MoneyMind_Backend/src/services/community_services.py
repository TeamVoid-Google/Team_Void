from sqlalchemy.orm import Session
from typing import List, Optional, Dict, Any
from sqlalchemy.sql import func
from sqlalchemy import desc, asc

from ..models.community_models import User, Post, Comment, Reply, Bookmark, Follow
from fastapi import HTTPException, UploadFile
import os
from config.settings import MEDIA_STORAGE_PATH
import uuid
import shutil

class CommunityService:
    def __init__(self, db_session: Session):
        self.db = db_session

    # User operations
    def get_user(self, user_id: int) -> Optional[User]:
        return self.db.query(User).filter(User.id == user_id).first()
    
    def get_user_by_handle(self, handle: str) -> Optional[User]:
        return self.db.query(User).filter(User.handle == handle).first()
    
    def create_user(self, username: str, handle: str, bio: str = None) -> User:
        if self.get_user_by_handle(handle):
            raise HTTPException(status_code=400, detail="Handle already exists")
        
        user = User(
            username=username,
            handle=handle,
            bio=bio
        )
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user
    
    def update_user(self, user_id: int, data: Dict[str, Any]) -> User:
        user = self.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        for key, value in data.items():
            if hasattr(user, key):
                setattr(user, key, value)
        
        self.db.commit()
        self.db.refresh(user)
        return user
    
    def upload_profile_image(self, user_id: int, file: UploadFile) -> str:
        user = self.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        os.makedirs(os.path.join(MEDIA_STORAGE_PATH, "profiles"), exist_ok=True)
        
        file_extension = file.filename.split(".")[-1]
        unique_filename = f"{uuid.uuid4()}.{file_extension}"
        file_path = os.path.join(MEDIA_STORAGE_PATH, "profiles", unique_filename)
        
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        user.profile_image = file_path
        self.db.commit()
        
        return file_path
    
    def follow_user(self, follower_id: int, followed_id: int) -> None:
        if follower_id == followed_id:
            raise HTTPException(status_code=400, detail="Users cannot follow themselves")
        
        existing_follow = self.db.query(Follow).filter(
            Follow.follower_id == follower_id,
            Follow.followed_id == followed_id
        ).first()
        
        if existing_follow:
            raise HTTPException(status_code=400, detail="Already following this user")
        
        follow = Follow(follower_id=follower_id, followed_id=followed_id)
        self.db.add(follow)
        self.db.commit()
    
    def unfollow_user(self, follower_id: int, followed_id: int) -> None:
        follow = self.db.query(Follow).filter(
            Follow.follower_id == follower_id,
            Follow.followed_id == followed_id
        ).first()
        
        if not follow:
            raise HTTPException(status_code=404, detail="Not following this user")
        
        self.db.delete(follow)
        self.db.commit()
    
    def get_followers(self, user_id: int) -> List[User]:
        return self.db.query(User).join(
            Follow, User.id == Follow.follower_id
        ).filter(Follow.followed_id == user_id).all()
    
    def get_following(self, user_id: int) -> List[User]:
        return self.db.query(User).join(
            Follow, User.id == Follow.followed_id
        ).filter(Follow.follower_id == user_id).all()
    
    def search_users(self, query: str, limit: int = 10) -> List[User]:
        return self.db.query(User).filter(
            (User.username.ilike(f"%{query}%")) | 
            (User.handle.ilike(f"%{query}%"))
        ).limit(limit).all()
    
    # Post operations
    def create_post(self, user_id: int, content: str, image_file: Optional[UploadFile] = None) -> Post:
        post = Post(
            user_id=user_id,
            content=content,
            has_image=bool(image_file)
        )
        
        self.db.add(post)
        self.db.flush()
        
        # Handle image upload
        if image_file:
            os.makedirs(os.path.join(MEDIA_STORAGE_PATH, "posts"), exist_ok=True)
            
            file_extension = image_file.filename.split(".")[-1]
            unique_filename = f"{uuid.uuid4()}.{file_extension}"
            file_path = os.path.join(MEDIA_STORAGE_PATH, "posts", unique_filename)
            
            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(image_file.file, buffer)
            
            post.image_url = file_path
        
        self.db.commit()
        self.db.refresh(post)
        return post
    
    def get_post(self, post_id: int) -> Optional[Post]:
        return self.db.query(Post).filter(Post.id == post_id).first()
    
    def get_user_posts(self, user_id: int, page: int = 1, per_page: int = 10) -> List[Post]:
        return self.db.query(Post).filter(
            Post.user_id == user_id
        ).order_by(
            desc(Post.created_at)
        ).offset((page - 1) * per_page).limit(per_page).all()
    
    def get_feed_posts(self, user_id: int, page: int = 1, per_page: int = 10) -> List[Post]:
        followed_users = self.db.query(Follow.followed_id).filter(Follow.follower_id == user_id).all()
        followed_ids = [user[0] for user in followed_users]
        
        if user_id not in followed_ids:
            followed_ids.append(user_id)
        
        return self.db.query(Post).filter(
            Post.user_id.in_(followed_ids)
        ).order_by(
            desc(Post.created_at)
        ).offset((page - 1) * per_page).limit(per_page).all()
    
    def get_for_you_posts(self, page: int = 1, per_page: int = 10) -> List[Post]:
        return self.db.query(Post).order_by(
            desc(Post.created_at)
        ).offset((page - 1) * per_page).limit(per_page).all()
    
    def like_post(self, user_id: int, post_id: int) -> None:
        user = self.get_user(user_id)
        post = self.get_post(post_id)
        
        if not user or not post:
            raise HTTPException(status_code=404, detail="User or post not found")
        
        if user in post.liked_by:
            raise HTTPException(status_code=400, detail="Post already liked")
        
        post.liked_by.append(user)
        self.db.commit()
    
    def unlike_post(self, user_id: int, post_id: int) -> None:
        user = self.get_user(user_id)
        post = self.get_post(post_id)
        
        if not user or not post:
            raise HTTPException(status_code=404, detail="User or post not found")
        
        if user not in post.liked_by:
            raise HTTPException(status_code=400, detail="Post not liked")
        
        post.liked_by.remove(user)
        self.db.commit()
    
    def bookmark_post(self, user_id: int, post_id: int) -> None:
        # Check if bookmark exists
        existing_bookmark = self.db.query(Bookmark).filter(
            Bookmark.user_id == user_id,
            Bookmark.post_id == post_id
        ).first()
        
        if existing_bookmark:
            raise HTTPException(status_code=400, detail="Post already bookmarked")
        
        bookmark = Bookmark(user_id=user_id, post_id=post_id)
        self.db.add(bookmark)
        self.db.commit()
    
    def remove_bookmark(self, user_id: int, post_id: int) -> None:
        bookmark = self.db.query(Bookmark).filter(
            Bookmark.user_id == user_id,
            Bookmark.post_id == post_id
        ).first()
        
        if not bookmark:
            raise HTTPException(status_code=404, detail="Bookmark not found")
        
        self.db.delete(bookmark)
        self.db.commit()
    
    def get_bookmarked_posts(self, user_id: int, page: int = 1, per_page: int = 10) -> List[Post]:
        return self.db.query(Post).join(
            Bookmark, Post.id == Bookmark.post_id
        ).filter(
            Bookmark.user_id == user_id
        ).order_by(
            desc(Post.created_at)
        ).offset((page - 1) * per_page).limit(per_page).all()
    
    # Comment operations
    def create_comment(self, user_id: int, post_id: int, text: str) -> Comment:
        comment = Comment(
            user_id=user_id,
            post_id=post_id,
            text=text
        )
        self.db.add(comment)
        self.db.commit()
        self.db.refresh(comment)
        return comment
    
    def get_post_comments(self, post_id: int) -> List[Comment]:
        return self.db.query(Comment).filter(
            Comment.post_id == post_id
        ).order_by(
            Comment.created_at
        ).all()
    
    def create_reply(self, user_id: int, comment_id: int, text: str) -> Reply:
        reply = Reply(
            user_id=user_id,
            comment_id=comment_id,
            text=text
        )
        self.db.add(reply)
        self.db.commit()
        self.db.refresh(reply)
        return reply
    
    def get_comment_replies(self, comment_id: int) -> List[Reply]:
        return self.db.query(Reply).filter(
            Reply.comment_id == comment_id
        ).order_by(
            Reply.created_at
        ).all()
    
    def like_comment(self, user_id: int, comment_id: int) -> None:
        user = self.get_user(user_id)
        comment = self.db.query(Comment).filter(Comment.id == comment_id).first()
        
        if not user or not comment:
            raise HTTPException(status_code=404, detail="User or comment not found")
        
        if user in comment.liked_by:
            raise HTTPException(status_code=400, detail="Comment already liked")
        
        comment.liked_by.append(user)
        self.db.commit()
    
    def unlike_comment(self, user_id: int, comment_id: int) -> None:
        user = self.get_user(user_id)
        comment = self.db.query(Comment).filter(Comment.id == comment_id).first()
        
        if not user or not comment:
            raise HTTPException(status_code=404, detail="User or comment not found")
        
        if user not in comment.liked_by:
            raise HTTPException(status_code=400, detail="Comment not liked")
        
        comment.liked_by.remove(user)
        self.db.commit()