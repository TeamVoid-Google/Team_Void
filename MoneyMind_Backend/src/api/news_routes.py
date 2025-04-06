from fastapi import APIRouter, HTTPException, Query
from typing import List, Dict, Any, Optional
import json
import logging
from ..services.news_service import NewsApiService
from pydantic import BaseModel

logger = logging.getLogger(__name__)

# Router object
router = APIRouter(prefix="/api/news", tags=["news"])

# Data models
class NewsSource(BaseModel):
    name: str
    url: Optional[str] = None

class NewsResponse(BaseModel):
    title: str
    url: Optional[str] = None
    description: Optional[str] = None
    source: Optional[Dict[str, Any]] = None
    urlToImage: Optional[str] = None
    publishedAt: Optional[str] = None
    category: Optional[str] = None

class NewsRequest(BaseModel):
    query: str
    country: str = "in"
    language: str = "en"
    limit: int = 10

@router.get("/trending", response_model=List[Dict[str, Any]])
async def get_trending_news(
    country: str = Query("in", description="Country code (e.g., 'in')"),
    language: str = Query("en", description="Language code (e.g., 'en')"),
    limit: int = Query(10, description="Number of news items to return")
):
    """Get trending financial news articles"""
    try:
        news_service = NewsApiService()
        news_json = news_service.get_specific_news("trending", country=country, language=language)
        news_data = json.loads(news_json)
        
        if isinstance(news_data, dict) and "error" in news_data:
            raise HTTPException(status_code=500, detail=news_data["error"])
        
        return news_data[:limit] if isinstance(news_data, list) else []
    except Exception as e:
        logger.error(f"Error fetching trending news: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/category/{category}", response_model=List[Dict[str, Any]])
async def get_news_by_category(
    category: str,
    country: str = Query("in", description="Country code (e.g., 'in')"),
    language: str = Query("en", description="Language code (e.g., 'en')"),
    limit: int = Query(10, description="Number of news items to return")
):
    """
    Get news articles by category
    
    Categories include: investments, market & economy, startups, business & fintech
    """
    try:
        news_service = NewsApiService()
        news_json = news_service.get_specific_news(category, country=country, language=language)
        news_data = json.loads(news_json)
        
        if isinstance(news_data, dict) and "error" in news_data:
            raise HTTPException(status_code=500, detail=news_data["error"])
        
        return news_data[:limit] if isinstance(news_data, list) else []
    except Exception as e:
        logger.error(f"Error fetching news for category {category}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/search", response_model=List[Dict[str, Any]])
async def search_news(request: NewsRequest):
    """Search for news articles based on query"""
    try:
        news_service = NewsApiService()
        news_json = news_service.get_specific_news(
            request.query, 
            country=request.country,
            language=request.language
        )
        news_data = json.loads(news_json)
        
        if isinstance(news_data, dict) and "error" in news_data:
            raise HTTPException(status_code=500, detail=news_data["error"])
        
        return news_data[:request.limit] if isinstance(news_data, list) else []
    except Exception as e:
        logger.error(f"Error searching news for query '{request.query}': {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/markets", response_model=List[Dict[str, Any]])
async def get_market_data():
    """Get market trend data from Google Finance"""
    try:
        news_service = NewsApiService()
        market_json = news_service.get_market_data()
        market_data = json.loads(market_json)
        
        if isinstance(market_data, dict) and "error" in market_data:
            raise HTTPException(status_code=500, detail=market_data["error"])
        
        return market_data
    except Exception as e:
        logger.error(f"Error fetching market data: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))