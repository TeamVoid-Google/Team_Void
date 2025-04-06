import logging
import json
import datetime
import google.generativeai as genai

from config import settings
from src.services.gemini_service import gemini_service
from src.services.serpapi_service import TOOL_FUNCTIONS_MAP

logger = logging.getLogger(__name__)

# --- Tool Definitions for Gemini ---
GoogleSearchTool = genai.types.FunctionDeclaration(
    name="google_search",
    description="Search Google for relevant, current, or specific information, especially for topics related to Indian finance, markets, or regulations.",
    parameters={
        'type': 'object',
        'properties': {
            'query': {
                'type': 'string',
                'description': "The specific search query for Google. Be precise."
            }
        },
        'required': ['query']
    }
)

YouTubeSearchTool = genai.types.FunctionDeclaration(
    name="youtube_search",
    description="Search YouTube for explanatory videos on financial concepts, investment strategies, or tutorials relevant to Indian users.",
     parameters={
        'type': 'object',
        'properties': {
            'query': {
                'type': 'string',
                'description': "The search query for YouTube videos (e.g., 'explain mutual funds india', 'stock market basics india')."
            }
        },
        'required': ['query']
    }
)

QNA_TOOLS = [GoogleSearchTool, YouTubeSearchTool]

# --- Agent Logic ---
def run_qna_agent(user_input: str, user_data: dict) -> tuple[str, dict]:
    """Handles general financial Q&A, uses search tools, and updates user history."""
    user_id = user_data['user_id']
    user_name = user_data.get("profile", {}).get("name", "there")

    logger.info(f"Running Q&A Agent for user {user_id}")

    previous_topics = user_data.get("preferences", {}).get("qna_topics_interest", [])
    context_prompt = f"The user ({user_name}) has previously shown interest in: {', '.join(previous_topics[-5:])}." if previous_topics else ""

    prompt = f"""
    You are a helpful financial Q&A assistant for users in India. Your name is MoneyMind.
    The user's name is {user_name}.
    {context_prompt}

    User's question: "{user_input}"

    Instructions:
    1.  Answer the question clearly, concisely, and accurately, focusing on the Indian context (e.g., Indian regulations, markets, financial products like PPF, NPS, specific banks).
    2.  If the question requires current information, specific data points, or details beyond general knowledge, use the 'google_search' tool. Formulate a good search query.
    3.  If the question asks for explanations or "how-to" guides, consider using the 'youtube_search' tool to find relevant videos. Formulate a good search query.
    4.  Integrate the information found from tools smoothly into your answer. Cite the source or link if appropriate (e.g., "According to [Source Name], ..."). If providing video suggestions, list the title and link.
    5.  Identify the main financial topic(s) discussed in the user's question (e.g., "Mutual Funds", "Stock Market", "Taxation", "Loans").
    6.  Be polite and conversational.

    Respond directly with the answer. Do not explicitly state which tool you are using unless suggesting videos or citing search results.
    """

    try:
        response_text = gemini_service.generate_with_tools(
            prompt=prompt,
            tools=QNA_TOOLS,
            tool_functions=TOOL_FUNCTIONS_MAP
        )

        # --- Update User Data ---
        topics = []
        keywords = ["mutual fund", "stock", "market", "tax", "loan", "investment", "sip", "ipo", "crypto", "insurance", "budget", "saving", "fd", "ppf", "nps", "gold"]
        for kw in keywords:
             if kw in user_input.lower():
                 topics.append(kw.capitalize())
        if not topics:
             topic_guess = user_input.split()[-2:]
             if topic_guess:
                 topics.append(" ".join(topic_guess).capitalize())

        current_interests = user_data.setdefault("preferences", {}).setdefault("qna_topics_interest", [])
        for topic in topics:
            if topic and topic not in current_interests:
                current_interests.append(topic)

        user_data.setdefault("history", {}).setdefault("qna_log", []).append({
            "question": user_input,
            "answer": response_text,
            "timestamp": datetime.datetime.now().isoformat()
        })

        return response_text, user_data

    except Exception as e:
        logger.error(f"Error in Q&A agent for user {user_id}: {e}", exc_info=True) 
        return "Sorry, I encountered an error while processing your question. Please try again.", user_data