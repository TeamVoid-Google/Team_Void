# src/services/news_service.py
import logging
import json
import requests
from config import settings

logger = logging.getLogger(__name__)

# SerpAPI configuration
SERPAPI_KEY = "97cefd646ce3aa29f9f42bc52fe8962fd749733acb7311472f322210256697ee" 
SERPAPI_BASE_URL = "https://serpapi.com/search.json"

class NewsApiService:
    def __init__(self, api_key=SERPAPI_KEY):
        self.api_key = api_key
        if self.api_key:
            logger.info("SerpAPI News Service Initialized")
        else:
            logger.warning("SerpAPI key not provided, service may not work properly")
    
    def get_specific_news(self, query: str, country: str = "in", language: str = "en") -> str:
        """
        Fetches news from SerpAPI Google News.
        
        Args:
            query: The search term (company, topic, or category).
            country: Country code (e.g., 'in' for India).
            language: Language code (e.g., 'en' for English).
        
        Returns:
            A JSON string containing news results, or an error message.
        """
        if not self.api_key:
            return json.dumps({"error": "API key not configured."})
        
        try:
            if query.lower() == "trending":
                return self.get_finance_news()
            elif query.lower() in ["investments", "market & economy", "startups", "business & fintech"]:
                return self.get_google_news(f"finance {query}")
            else:
                return self.get_google_news(query, country, language)
                
        except Exception as e:
            logger.error(f"Unexpected error in NewsApiService: {e}")
            return json.dumps({"error": f"Failed to fetch news: {e}"})
    
    def get_google_news(self, query: str, country: str = "in", language: str = "en") -> str:
        """Fetch news from Google News via SerpAPI"""
        try:
            params = {
                "engine": "google_news",
                "q": query,
                "gl": country,
                "hl": language,
                "api_key": self.api_key
            }
            
            response = requests.get(SERPAPI_BASE_URL, params=params)
            response.raise_for_status()
            
            data = response.json()
            logger.info(f"Successfully fetched Google News for query: {query}")
            
            # Extract and transform the news results
            news_articles = []
            if "news_results" in data:
                for article in data["news_results"]:
                    transformed_article = {
                        "title": article.get("title", "No Title"),
                        "description": article.get("snippet", ""),
                        "url": article.get("link", ""),
                        "urlToImage": article.get("thumbnail", ""),
                        "publishedAt": article.get("date", ""),
                        "source": {"name": article.get("source", {}).get("name", "Unknown Source")},
                        "category": query.capitalize()
                    }
                    news_articles.append(transformed_article)
            
            return json.dumps(news_articles)
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Error fetching Google News from SerpAPI: {e}")
            return json.dumps({"error": f"Failed to fetch news: {e}"})
    
    def get_finance_news(self) -> str:
        """Fetch financial news from Google Finance Markets via SerpAPI"""
        try:
            params = {
                "engine": "google_finance_markets",
                "trend": "indexes",
                "api_key": self.api_key
            }
            
            response = requests.get(SERPAPI_BASE_URL, params=params)
            response.raise_for_status()
            
            data = response.json()
            logger.info("Successfully fetched Finance Market news")
            
            # Extract and transform the news results
            news_articles = []
            if "news_results" in data:
                for article in data["news_results"]:
                    transformed_article = {
                        "title": article.get("snippet", "No Title"),
                        "description": article.get("snippet", ""),
                        "url": article.get("link", ""),
                        "urlToImage": article.get("thumbnail", ""),
                        "publishedAt": article.get("date", ""),
                        "source": {"name": article.get("source", "Unknown Source")},
                        "category": "Trending"
                    }
                    news_articles.append(transformed_article)
            
            return json.dumps(news_articles)
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Error fetching Finance news from SerpAPI: {e}")
            return json.dumps({"error": f"Failed to fetch finance news: {e}"})
    
    def get_market_data(self) -> str:
        """Fetch market trend data from Google Finance Markets via SerpAPI"""
        try:
            params = {
                "engine": "google_finance_markets",
                "trend": "indexes",
                "api_key": self.api_key
            }
            
            response = requests.get(SERPAPI_BASE_URL, params=params)
            response.raise_for_status()
            
            data = response.json()
            logger.info("Successfully fetched Market data")
            
            # Return full market data including trends and indices
            if "market_trends" in data:
                return json.dumps(data["market_trends"])
            else:
                return json.dumps([])
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Error fetching Market data from SerpAPI: {e}")
            return json.dumps({"error": f"Failed to fetch market data: {e}"})