#src/services/serpapi_service.py
from serpapi import GoogleSearch
from config import settings
import logging
import json

logger = logging.getLogger(__name__)

class SerpApiService:
    def __init__(self, api_key=settings.SERPAPI_API_KEY):
        if not api_key:
            raise ValueError("SerpApi API Key is required.")
        self.api_key = api_key
        logger.info("SerpApi Service Initialized")

    def _search(self, params: dict) -> dict:
        """Internal method to perform search and handle basic errors."""
        params['api_key'] = self.api_key
        try:
            search = GoogleSearch(params)
            results = search.get_dict()
            if "error" in results:
                logger.error(f"SerpApi Error: {results['error']}")
                return {"error": results['error']}
            logger.info(f"SerpApi search successful for query: {params.get('q') or params.get('search_query')}")
            return results
        except Exception as e:
            logger.error(f"Exception during SerpApi search: {e}")
            return {"error": f"An exception occurred: {e}"}

    def google_search(self, query: str, num_results: int = 3) -> str:
        """Performs Google Search (organic results)."""
        params = {
            "q": query,
            "gl": "in", 
            "hl": "en", 
            "num": num_results 
        }
        results = self._search(params)
        organic_results = results.get("organic_results", [])
        filtered_results = [
            {"title": r.get("title"), "link": r.get("link"), "snippet": r.get("snippet")}
            for r in organic_results[:num_results] 
        ]
        return json.dumps(filtered_results)

    def youtube_search(self, query: str, num_results: int = 2) -> str:
        """Performs YouTube Search."""
        params = {
            "search_query": query,
            "engine": "youtube",
            "gl": "in",
        }
        results = self._search(params)
        video_results = results.get("video_results", [])
        filtered_results = [
            {"title": r.get("title"), "link": r.get("link"), "channel": r.get("channel", {}).get("name"), "published_date": r.get("published_date")}
            for r in video_results[:num_results]
        ]
        return json.dumps(filtered_results)

    def get_news(self, query: str, num_results: int = 5) -> str:
        """Performs Google News Search."""
        search_query = query
        if "india" not in query.lower():
            search_query += " India"

        params = {
            "q": search_query,
            "tbm": "nws", 
            "gl": "in",
            "hl": "en",
            "num": num_results
        }
        results = self._search(params)
        news_results = results.get("news_results", [])
        filtered_results = [
            {"title": r.get("title"), "link": r.get("link"), "snippet": r.get("snippet"), "source": r.get("source"), "date": r.get("date")}
            for r in news_results[:num_results]
        ]
        return json.dumps(filtered_results)

# Instantiate the service
serpapi_service = SerpApiService()

# --- Define Tool Functions (callable by Gemini) ---
def google_search_tool_func(query: str) -> str:
    """Callable function for Google Search Tool."""
    logger.info(f"--- TOOL CALL: Google Search for: {query} ---")
    return serpapi_service.google_search(query=query)

def youtube_search_tool_func(query: str) -> str:
    """Callable function for YouTube Search Tool."""
    logger.info(f"--- TOOL CALL: YouTube Search for: {query} ---")
    return serpapi_service.youtube_search(query=query)

def get_financial_news_tool_func(query: str) -> str:
    """Callable function for Financial News Tool."""
    logger.info(f"--- TOOL CALL: Fetching News for: {query} (India Focus) ---")
    return serpapi_service.get_news(query=query)

# Dictionary mapping function names to actual functions
TOOL_FUNCTIONS_MAP = {
    "google_search": google_search_tool_func,
    "youtube_search": youtube_search_tool_func,
    "get_financial_news": get_financial_news_tool_func,
}