import logging
import json
import datetime
import google.generativeai as genai
import re 

from config import settings
from src.services.gemini_service import gemini_service
from src.services.serpapi_service import TOOL_FUNCTIONS_MAP

logger = logging.getLogger(__name__)

GetNewsTool = genai.types.FunctionDeclaration(
    name="get_financial_news", 
    description=(
        "Fetches recent financial/business news OR key market indicators using SerpApi. "
        "Use for queries about specific Indian companies (e.g., Reliance, Infosys), "
        "stock tickers (e.g., RELIANCE.NS), financial topics (e.g., 'RBI policy', 'Indian IPO market'), "
        "commodities (e.g., 'gold price India'), or general market status (e.g., 'Indian stock market performance', 'Nifty 50 status'). "
        "The tool specifically targets the Indian context (gl=in)."
    ),
    parameters={
        'type': 'object',
        'properties': {
            'query': {
                'type': 'string',
                'description': (
                    "The specific topic, company name, ticker symbol, commodity, or market status phrase to search for news or market data. "
                    "Examples: 'latest RBI policy news', 'Infosys quarterly results', 'gold price trend India', 'Sensex current status', 'Indian EV market news'."
                )
            }
        },
        'required': ['query']
    }
)

NEWS_TOOLS = [GetNewsTool]

# --- Agent Logic ---
def run_news_agent(user_input: str, user_data: dict) -> tuple[str, dict]:
    """
    Orchestrates fetching financial news or market data using the 'get_financial_news'
    tool (powered by SerpApi via gemini_service) and updates user history.
    """
    user_id = user_data.get('user_id', 'unknown_user')
    logger.info(f"Running News Agent for user {user_id}. Input: '{user_input}'")

    # --- Context Setting ---
    liked_companies = user_data.get("preferences", {}).get("liked_companies", [])
    liked_topics = user_data.get("preferences", {}).get("news_interaction_topics", [])
    context_prompt = ""
    if liked_topics or liked_companies:
        context_parts = []
        if liked_topics:
            context_parts.append(f"User previously showed interest in news about: {', '.join(liked_topics[-5:])}")
        if liked_companies:
            context_parts.append(f"They follow companies like: {', '.join(liked_companies[-5:])}")
        context_prompt = ". ".join(context_parts) + "."

    # --- Refined Prompt for Gemini ---
    prompt = f"""
    You are MoneyMind, a specialized financial assistant for India. Your task is to provide relevant financial news or market summaries based on user requests by using the available tool.
    {context_prompt}
    The user's request is: "{user_input}"

    **Your Process:**
    1.  Analyze the user's request: "{user_input}".
    2.  Determine the most relevant query term for the Indian context (e.g., 'Reliance Industries news', 'Indian stock market indices', 'RBI monetary policy update', 'gold price India').
    3.  **Crucially, you MUST call the 'get_financial_news' function tool with this specific query.** This tool uses SerpApi (interfacing with Google News and Google Finance) to fetch real-time data. **Do not answer from your internal knowledge or state you cannot access current news/market data.**
    4.  The tool will execute and return a formatted string containing either:
        a) A list of recent news headlines, sources, snippets, and links.
        b) A summary of key relevant market indicators (like Nifty 50, Sensex) with current values and changes.
        c) A message indicating if no specific results were found for the query by SerpApi.
    5.  Wait for the tool's response string.
    6.  **Synthesize the information from the tool's response string into a concise, user-friendly summary.**
        *   If news results were returned: Present 2-4 key headlines with their source and a brief snippet. Mention links if available in the tool output.
        *   If market data was returned: Clearly state the key index/market figures provided by the tool (e.g., "Nifty 50 is at X, up/down Y points...").
        *   If the tool indicated no results: Inform the user politely, mentioning the specific query tried (e.g., "I searched for '{{query}}' using SerpApi but couldn't find recent specific news/data."). ## <-- CORRECTED LINE
    7.  Determine the primary topic/entity that was searched for using the tool based on the query you formulated.

    **Respond directly to the user with the synthesized summary based *only* on the data provided by the 'get_financial_news' tool.** Start appropriately, e.g., "Okay, here's the latest I found via SerpApi on [topic]:". Do not include technical details about the tool call itself unless reporting an explicit "no results" message from the tool.
    """

    try:
        logger.debug(f"Calling Gemini with tools. Prompt snippet: {prompt[:250]}...")

        if "get_financial_news" not in TOOL_FUNCTIONS_MAP or not callable(TOOL_FUNCTIONS_MAP.get("get_financial_news")):
             logger.error("CRITICAL: 'get_financial_news' function not found or not callable in TOOL_FUNCTIONS_MAP!")
             return "Sorry, there's a configuration issue with the news fetching tool. Please notify support.", user_data

        response_text = gemini_service.generate_with_tools(
            prompt=prompt,
            tools=NEWS_TOOLS,
            tool_functions=TOOL_FUNCTIONS_MAP
        )

        logger.info(f"News Agent received response from Gemini service for user {user_id}.")
        logger.debug(f"Final Response Text from Gemini: {response_text}")

        # --- Post-processing and Data Update ---

        topic_identified = "Unknown/General"
        match = re.search(r"(?:news|update)\s+(?:about|on|for)\s+(.+)", user_input, re.IGNORECASE)
        if match:
            topic_identified = match.group(1).strip().rstrip('?.!,')
        else:
            potential_topics = [w for w in user_input.split() if w.istitle() or w.isupper() or w.lower() in ["gold", "silver", "market", "ipo", "rbi", "nifty", "sensex", "stock", "stocks", "bank", "banks", "index", "indices"]]
            if potential_topics:
                topic_identified = " ".join(potential_topics)
            elif len(user_input.split()) < 5:
                 topic_identified = user_input.strip().rstrip('?.!,')
            else:
                 topic_identified = "General financial topic"

        if not topic_identified: topic_identified = "General financial news"
        logger.info(f"Identified news topic for logging: '{topic_identified}'")

        failure_phrases = [
            "i cannot fulfill", "lack the functionality", "do not have enough information",
            "beyond my current capabilities", "unable to provide news", "cannot access real-time data"
        ]
        is_unexpected_failure_response = any(phrase in response_text.lower() for phrase in failure_phrases)

        # Update user data
        if "preferences" not in user_data: user_data["preferences"] = {}
        if "news_interaction_topics" not in user_data["preferences"]: user_data["preferences"]["news_interaction_topics"] = []

        current_topics = user_data["preferences"]["news_interaction_topics"]
        if topic_identified and topic_identified not in current_topics:
            current_topics.append(topic_identified)
            user_data["preferences"]["news_interaction_topics"] = current_topics[-20:]

        if "history" not in user_data: user_data["history"] = {}
        if "news_log" not in user_data["history"]: user_data["history"]["news_log"] = []

        user_data["history"]["news_log"].append({
            "request": user_input,
            "response_received": response_text,
            "topic_identified_for_log": topic_identified,
            "timestamp": datetime.datetime.now().isoformat(),
            "unexpected_failure": is_unexpected_failure_response
        })

        if is_unexpected_failure_response:
             logger.warning(f"Gemini response indicated unexpected inability for user {user_id} on topic '{topic_identified}'. Original response: '{response_text}'")
             final_response = response_text
        else:
             final_response = response_text

        return final_response, user_data

    except Exception as e:
        logger.error(f"Error during News Agent execution for user {user_id}: {e}", exc_info=True)
        # Log error in user history
        if "history" not in user_data: user_data["history"] = {}
        if "news_log" not in user_data["history"]: user_data["history"]["news_log"] = []
        user_data["history"]["news_log"].append({
            "request": user_input,
            "response_received": f"Agent Error: {type(e).__name__}",
            "topic_identified_for_log": "Error",
            "timestamp": datetime.datetime.now().isoformat(),
            "unexpected_failure": True # Mark as failure
        })
        return "Sorry, an internal error occurred while processing your news request. Please try again later.", user_data