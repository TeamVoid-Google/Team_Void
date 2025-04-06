import logging
import json
import datetime
import re

from src.services.gemini_service import gemini_service
from config import settings

logger = logging.getLogger(__name__)

# --- Agent Logic ---
def run_portfolio_agent(user_input: str, user_data: dict) -> tuple[str, dict]:
    """Generates portfolio suggestions based on risk profile and handles adjustments."""
    user_id = user_data['user_id']
    profile = user_data.get("profile", {})
    risk_category = profile.get("risk_category")
    risk_score = profile.get("risk_score")
    preferences = user_data.get("preferences", {})
    history = user_data.get("history", {})
    last_suggestion = history.get("portfolio_suggestions", [])[-1] if history.get("portfolio_suggestions") else None

    logger.info(f"Running Portfolio Agent for user {user_id}. Risk: {risk_category} ({risk_score})")

    # --- Check if Risk Profile Exists ---
    if not risk_category or risk_score is None:
        logger.warning(f"User {user_id}: Portfolio requested but risk profile incomplete.")
        return "I need to understand your financial risk profile first. Shall we complete that now?", user_data

    # --- Define Base Allocation Rules ---
    allocations = {"low": 50, "medium": 30, "high": 20}
    if risk_category == "Low Risk Tolerance": 
        allocations = {"low": 65, "medium": 25, "high": 10}
    elif risk_category == "Moderate Risk Tolerance": 
        allocations = {"low": 40, "medium": 40, "high": 20}
    elif risk_category == "High Risk Tolerance": 
        allocations = {"low": 20, "medium": 40, "high": 40}

    # --- Prepare Prompt for Gemini ---
    adjustment_context = ""
    is_adjustment_request = any(word in user_input.lower() for word in ["adjust", "change", "modify", "remove", "add", "less", "more"])
    if is_adjustment_request and last_suggestion:
        adjustment_context = f"""
        The user is asking to adjust the previous suggestion.
        User Adjustment Request: "{user_input}"
        Previous Suggestion Context: {json.dumps(last_suggestion['portfolio'])}

        Modify the portfolio breakdown based on the user's request while trying to maintain the overall risk category allocation ({allocations['low']}% Low, {allocations['medium']}% Medium, {allocations['high']}% High). Reallocate percentages within or across categories if necessary to accommodate the request (e.g., if they want 0% crypto, reallocate that percentage).
        """
    else:
         adjustment_context = f"""
         Generate an initial portfolio based on the user's profile.
         User Request (if specific): "{user_input}"
         """

    prompt = f"""
    You are MoneyMind, an AI assistant providing personalized investment portfolio suggestions for users in India.
    User Profile:
    - Risk Category: {risk_category}
    - Financial Stability Score: {risk_score}/100
    - User Preferences (Likes): {json.dumps(preferences)}

    Target Overall Allocation:
    - Low-Risk Investments: {allocations['low']}%
    - Medium-Risk Investments: {allocations['medium']}%
    - High-Risk Investments: {allocations['high']}%

    {adjustment_context}

    Instructions:
    1. Create a detailed portfolio breakdown within the target allocation percentages.
    2. Use investment types relevant and accessible in INDIA (e.g., PPF, NPS, Indian Equities - Large/Mid/Small Cap, G-Secs, Corporate Bonds, Gold SGBs/ETFs, REITs India, Liquid/Hybrid Funds). Avoid suggesting products not easily available in India unless specified.
    3. Ensure the percentages within each risk category breakdown sum up *exactly* to that category's target percentage ({allocations['low']}% for Low, etc.).
    4. Ensure the sum of all category percentages (low + medium + high) equals 100%.
    5. Structure the output *strictly* as a JSON object containing ONLY the "portfolio_allocation" key, following this schema:
       {{
         "portfolio_allocation": {{
           "low_risk_investments": {{
             "percentage": {allocations['low']},
             "breakdown": {{ "asset_name_india_1": percentage, "asset_name_india_2": percentage, ... }}
           }},
           "medium_risk_investments": {{
             "percentage": {allocations['medium']},
             "breakdown": {{ "asset_name_india_3": percentage, "asset_name_india_4": percentage, ... }}
           }},
           "high_risk_investments": {{
             "percentage": {allocations['high']},
             "breakdown": {{ "asset_name_india_5": percentage, "asset_name_india_6": percentage, ... }}
           }}
         }}
       }}
    6. Use snake_case for keys in the JSON breakdown (e.g., "government_bonds_gsecs", "indian_equity_large_cap").
    7. Double-check all percentage sums before finalizing the JSON.
    8. If suggesting volatile assets like Crypto, keep the percentage very small, especially for lower risk profiles, and mention the high risk.

    Generate ONLY the JSON object as requested. No introductory text, no explanations outside the JSON.
    """

    try:
        logger.info(f"Generating portfolio suggestion for {user_id} with prompt...")
        response = gemini_service.generate_text(prompt=prompt) 

        # --- Parse Response and Validate ---
        json_match = re.search(r'```json\s*(\{.*?\})\s*```', response, re.DOTALL)
        if json_match:
            json_str = json_match.group(1)
        else:
             json_str = response.strip()
             if not (json_str.startswith('{') and json_str.endswith('}')):
                  raise ValueError("Response doesn't contain the expected JSON structure.")

        portfolio_data = json.loads(json_str)

        # --- Basic Validation of the returned structure ---
        if "portfolio_allocation" not in portfolio_data:
            raise ValueError("Missing 'portfolio_allocation' key in generated JSON.")

        alloc = portfolio_data["portfolio_allocation"]
        total_perc = 0
        categories = ["low_risk_investments", "medium_risk_investments", "high_risk_investments"]
        for cat_key in categories:
            if cat_key not in alloc:
                 raise ValueError(f"Missing category '{cat_key}' in generated JSON.")
            cat_perc = alloc[cat_key].get("percentage", 0)
            total_perc += cat_perc
            breakdown = alloc[cat_key].get("breakdown", {})
            breakdown_sum = sum(breakdown.values())
            if not (cat_perc - 0.1 <= breakdown_sum <= cat_perc + 0.1):
                logger.warning(f"Category '{cat_key}' breakdown sum ({breakdown_sum}) doesn't match category percentage ({cat_perc}).")

        if not (99.9 <= total_perc <= 100.1):
             logger.warning(f"Total portfolio percentage ({total_perc}) is not 100%.")

        logger.info(f"Portfolio JSON generated and parsed successfully for {user_id}.")

        # --- Store Suggestion ---
        suggestion_entry = {
            "timestamp": datetime.datetime.now().isoformat(),
            "request": user_input, 
            "risk_category_at_time": risk_category,
            "risk_score_at_time": risk_score,
            "portfolio": alloc 
        }
        user_data.setdefault("history", {}).setdefault("portfolio_suggestions", []).append(suggestion_entry)

        # --- Format for User ---
        readable_output = f"Okay {profile.get('name', 'there')}, based on your '{risk_category}' profile "
        if is_adjustment_request:
             readable_output += f"and your request ('{user_input}'), here's an adjusted suggestion:\n\n"
        else:
             readable_output += f"(Score: {risk_score}), here's a suggested portfolio allocation:\n\n"

        for risk_level_key, details in alloc.items():
            level_name = risk_level_key.replace("_", " ").title()
            readable_output += f"**{level_name} ({details.get('percentage', 0)}%)**\n"
            breakdown = details.get('breakdown', {})
            if breakdown:
                for asset_key, percent in breakdown.items():
                    asset_name = asset_key.replace("_", " ").title()
                    readable_output += f"- {asset_name}: {percent}%\n"
            else:
                 readable_output += "- (No specific assets listed)\n"
            readable_output += "\n"

        readable_output += ("\n**Disclaimer:** This is an AI-generated suggestion based on your inputs and general principles. "
                            "It is not financial advice. All investments involve risk. Please consult with a SEBI-registered "
                            "financial advisor before making any investment decisions.")

        return readable_output, user_data

    except json.JSONDecodeError as e:
        logger.error(f"Error decoding JSON from Gemini portfolio response for user {user_id}: {e}\nRaw response:\n{response}")
        return "Sorry, I generated a portfolio suggestion, but had trouble formatting it correctly. Could you try asking again?", user_data
    except ValueError as e:
        logger.error(f"Validation Error for generated portfolio for user {user_id}: {e}\nRaw response:\n{response}")
        return f"Sorry, I encountered an issue generating the portfolio suggestion ({e}). Please try again.", user_data
    except Exception as e:
        logger.error(f"Unexpected error in Portfolio agent for user {user_id}: {e}")
        return "Sorry, an unexpected error occurred while generating the portfolio suggestion.", user_data