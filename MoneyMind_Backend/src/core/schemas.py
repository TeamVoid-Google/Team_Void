from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List


class NewsSource(BaseModel):
    """Schema for a news source"""
    name: str
    url: Optional[str] = None

class NewsResponse(BaseModel):
    """Schema for a news article response"""
    title: str
    url: Optional[str] = None
    snippet: Optional[str] = None
    description: Optional[str] = None
    source: Optional[NewsSource] = None
    urlToImage: Optional[str] = None
    publishedAt: Optional[str] = None
    category: Optional[str] = None

class NewsRequest(BaseModel):
    """Schema for a news search request"""
    query: str
    country: str = "in"
    language: str = "en"
    limit: int = 10