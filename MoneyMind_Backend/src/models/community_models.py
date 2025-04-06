from sqlalchemy import Column, Integer, String, Text, Boolean, ForeignKey, DateTime, Table
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

# Association table for post likes
post_likes = Table(
    'post_likes',
    Base.metadata,
    Column('user_id', Integer, ForeignKey('users.id')),
    Column('post_id', Integer, ForeignKey('posts.id')),
)

# Association table for comment likes
comment_likes = Table(
    'comment_likes',
    Base.metadata,
    Column('user_id', Integer, ForeignKey('users.id')),
    Column('comment_id', Integer, ForeignKey('comments.id')),
)

class User(Base):
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True)
    username = Column(String(50), unique=True, nullable=False)
    handle = Column(String(50), unique=True, nullable=False)
    bio = Column(String(255), nullable=True)
    profile_image = Column(String(255), nullable=True) 
    
    # Relationships
    posts = relationship("Post", back_populates="user")
    comments = relationship("Comment", back_populates="user")
    replies = relationship("Reply", back_populates="user")
    liked_posts = relationship("Post", secondary=post_likes, back_populates="liked_by")
    bookmarked_posts = relationship("Post", secondary="bookmarks", back_populates="bookmarked_by")
    following = relationship(
        "User",
        secondary="follows",
        primaryjoin="User.id==follows.c.follower_id",
        secondaryjoin="User.id==follows.c.followed_id",
        backref="followers"
    )
    
    # Authentication fields
    """
    email = Column(String(100), unique=True, nullable=False)
    password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())
    """

class Post(Base):
    __tablename__ = 'posts'
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    content = Column(Text, nullable=False)
    has_image = Column(Boolean, default=False)
    image_url = Column(String(255), nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="posts")
    comments = relationship("Comment", back_populates="post", cascade="all, delete-orphan")
    liked_by = relationship("User", secondary=post_likes, back_populates="liked_posts")
    bookmarked_by = relationship("User", secondary="bookmarks", back_populates="bookmarked_posts")

class Comment(Base):
    __tablename__ = 'comments'
    
    id = Column(Integer, primary_key=True)
    post_id = Column(Integer, ForeignKey('posts.id'), nullable=False)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    text = Column(Text, nullable=False)
    created_at = Column(DateTime, server_default=func.now())
    
    # Relationships
    post = relationship("Post", back_populates="comments")
    user = relationship("User", back_populates="comments")
    replies = relationship("Reply", back_populates="comment", cascade="all, delete-orphan")
    liked_by = relationship("User", secondary=comment_likes)

class Reply(Base):
    __tablename__ = 'replies'
    
    id = Column(Integer, primary_key=True)
    comment_id = Column(Integer, ForeignKey('comments.id'), nullable=False)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    text = Column(Text, nullable=False)
    created_at = Column(DateTime, server_default=func.now())
    
    # Relationships
    comment = relationship("Comment", back_populates="replies")
    user = relationship("User", back_populates="replies")

class Bookmark(Base):
    __tablename__ = 'bookmarks'
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    post_id = Column(Integer, ForeignKey('posts.id'), nullable=False)
    created_at = Column(DateTime, server_default=func.now())

class Follow(Base):
    __tablename__ = 'follows'
    
    id = Column(Integer, primary_key=True)
    follower_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    followed_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    created_at = Column(DateTime, server_default=func.now())