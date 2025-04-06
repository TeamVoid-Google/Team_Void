import logging
from typing import Optional

from src.data_manager.json_manager import json_manager
from src.services.gemini_service import gemini_service
from config import settings

from src.agents.qna_agent import run_qna_agent
from src.agents.news_agent import run_news_agent
from src.agents.profile_agent import run_user_profile_agent
from src.agents.portfolio_agent import run_portfolio_agent

logger = logging.getLogger(__name__)

AGENT_INTENTS = [
    "Q&A",
    "News Request",   
    "Profile Update", 
    "Portfolio Request",
]

def route_request(user_id: str, user_input: str) -> str:
    """
    Main orchestrator. Loads data, determines intent, calls the appropriate agent,
    saves data, and returns the response.
    """
    logger.info(f"Routing request for user {user_id}. Input: '{user_input}'")

    # --- 1. Load User Data ---
    user_data = json_manager.load_user_data(user_id)
    user_name = user_data.get("profile", {}).get("name", "there")

    if not user_input or not user_input.strip():
        return f"Hello {user_name}, how can I help with your financial questions today?"

    # --- 2. Check for Ongoing Profile Conversation ---
    state = user_data.get("conversation_state", {})
    pending_profile_question = state.get("pending_question")
    last_agent = state.get("last_agent")

    if pending_profile_question and last_agent == "UserProfileAgent":
        logger.info(f"User {user_id}: Continuing profile conversation.")
        response_text, updated_data = run_user_profile_agent(user_input, user_data)

        if not updated_data.get("conversation_state", {}).get("pending_question") and \
           "Would you like portfolio suggestions" in response_text:
             pass
        
        json_manager.save_user_data(user_id, updated_data)
        return response_text

    # --- 3. Determine Intent (if not in profiling) ---
    input_lower = user_input.lower()
    intent = None
    if any(kw in input_lower for kw in ["what is", "explain", "how does", "?", "tell me about"]):
         intent = "Q&A"
    elif any(kw in input_lower for kw in ["news", "update on", "market", "stock price"]):
         intent = "News Request"
    elif any(kw in input_lower for kw in ["portfolio", "suggest investment", "asset allocation", "adjust portfolio"]):
         intent = "Portfolio Request"
    elif any(kw in input_lower for kw in ["my profile", "risk tolerance", "update my income"]):
         intent = "Profile Update" 

    if not intent:
        logger.info(f"User {user_id}: Using LLM for intent classification.")
        intent = gemini_service.classify_intent(user_input, AGENT_INTENTS)
        logger.info(f"User {user_id}: Classified intent: {intent}")


    # --- 4. Route to Appropriate Agent ---
    response_text = f"Sorry {user_name}, I'm not sure how to respond to that." 
    updated_data = user_data 

    try:
        if intent == "Q&A":
            response_text, updated_data = run_qna_agent(user_input, user_data)
        elif intent == "News Request":
            response_text, updated_data = run_news_agent(user_input, user_data)
        elif intent == "Profile Update":
             logger.info(f"User {user_id}: Routing to Profile Agent based on intent/keywords.")
             response_text, updated_data = run_user_profile_agent(user_input, user_data)
        elif intent == "Portfolio Request":
            response_text, updated_data = run_portfolio_agent(user_input, user_data)
            if "understand your financial risk profile first" in response_text:
                 logger.info(f"User {user_id}: Portfolio needs profile. Triggering profile agent.")
                 response_text, updated_data = run_user_profile_agent(None, updated_data) 
        elif intent == "Unclear/General":
            response_text = f"Hi {user_name}! How can I help you with your finances today? You can ask me questions, get news, assess your risk profile, or get portfolio ideas."
        else:
            logger.warning(f"User {user_id}: Unknown intent classified: {intent}")
            response_text = f"Sorry {user_name}, I didn't understand that request type ({intent})."

    except Exception as e:
        logger.error(f"Error processing request for user {user_id} after intent routing ({intent}): {e}", exc_info=True)
        response_text = f"Sorry {user_name}, an unexpected error occurred while handling your request. Please try again."
        updated_data = user_data 

    # --- 5. Save Updated User Data ---
    try:
        if updated_data.get("conversation_state",{}).get("last_agent") is not None:
            pass 
        elif intent != "Unclear/General":
             pass 

        save_successful = json_manager.save_user_data(user_id, updated_data)
        if not save_successful:
             logger.error(f"CRITICAL: Failed to save updated data for user {user_id}!")

    except Exception as e:
         logger.error(f"CRITICAL: Exception during final data save for user {user_id}: {e}", exc_info=True)


    # --- 6. Return Response ---
    return response_text