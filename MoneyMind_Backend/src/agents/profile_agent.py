import logging
import datetime
from typing import Optional

from src.core.risk_calculator import calculate_risk_score
from config import settings 

logger = logging.getLogger(__name__)

# --- Define Questions and Options ---
QUESTIONS = {
    "income_source": ("What is your primary source of income?", ["Salary", "Business", "Investments", "Others"]),
    "income_stability": ("How stable is your income?", ["Very stable", "Somewhat stable", "Unstable"]),
    "savings_percentage": ("What percentage of your income do you typically save or invest each month?", ["Less than 10%", "10-30%", "More than 30%"]),
    "has_loans": ("Do you have any outstanding loans or EMIs (like home, car, personal loans)?", ["No", "Yes, but manageable", "Yes, multiple loans"]),
    "loan_payment_percentage": ("Approximately what percentage of your monthly income goes towards loan/EMI payments?", ["Less than 20%", "20-50%", "More than 50%"]), 
    "credit_usage_frequency": ("How often do you use credit cards or short-term loans to cover regular monthly expenses?", ["Rarely", "Sometimes", "Often"]),
    "investment_preference": ("How do you generally prefer to invest your money?", ["Fixed Deposits & Savings", "Mutual Funds & Stocks", "High-risk investments"]), 
    "reaction_to_loss": ("Imagine your investments dropped 20% in value over a short period. How would you most likely react?", ["Sell immediately", "Wait and watch", "Invest more"]),
    "emergency_fund": ("Do you have an emergency fund (savings for unexpected expenses) covering at least 6 months of your essential living costs?", ["Yes", "No"]),
    "missed_payments": ("In the last 12 months, have you missed any loan EMI or credit card payments?", ["No", "Yes"]),
}

# --- Agent Logic ---
def run_user_profile_agent(user_input: Optional[str], user_data: dict) -> tuple[str, dict]:
    """
    Manages the risk profiling conversation, collects parameters, and calculates score.
    user_input is None when agent is triggered proactively (e.g., by main agent).
    """
    user_id = user_data['user_id']
    profile = user_data.setdefault("profile", settings.DEFAULT_USER_STRUCTURE["profile"])
    params = profile.setdefault("risk_parameters", settings.DEFAULT_USER_STRUCTURE["profile"]["risk_parameters"])
    state = user_data.setdefault("conversation_state", settings.DEFAULT_USER_STRUCTURE["conversation_state"])
    pending_question_key = state.get("pending_question")

    logger.info(f"Running User Profile Agent for user {user_id}. Pending: {pending_question_key}. Input: {user_input}")

    response = ""

    # --- 1. Process Answer if a question was pending ---
    if pending_question_key and user_input:
        if pending_question_key not in QUESTIONS:
             logger.error(f"Invalid pending_question_key '{pending_question_key}' found in state for user {user_id}.")
             state["pending_question"] = None 
             pending_question_key = None 
             response = "There was an issue with the previous question. Let's try again. "
        else:
            question_text, options = QUESTIONS[pending_question_key]
            validated_answer = None
            user_input_lower = user_input.lower()
            for option in options:
                if option.lower() in user_input_lower or \
                   (option == "Yes" and "yes" in user_input_lower) or \
                   (option == "No" and "no" in user_input_lower):
                    if "%" in option: 
                         if any(num in user_input_lower for num in option.replace('%','').replace('<','').replace('>','').split('-')):
                              validated_answer = option
                              break
                    else:
                        validated_answer = option
                        break

            if validated_answer:
                logger.info(f"User {user_id} answered '{validated_answer}' for {pending_question_key}")
                params[pending_question_key] = validated_answer
                state["pending_question"] = None 
                pending_question_key = None 
                if pending_question_key == "has_loans" and validated_answer == "No":
                    params["loan_payment_percentage"] = "N/A"
            else:
                # Re-ask the question if validation fails
                logger.warning(f"User {user_id} input '{user_input}' not validated for options: {options}")
                response = f"Sorry, I didn't quite understand that. Please choose one of the options. {question_text} ({', '.join(options)})"
                state["last_agent"] = "UserProfileAgent"
                return response, user_data

    # --- 2. Find the next missing parameter ---
    next_question_key = None
    for key in QUESTIONS.keys():
        if key == "loan_payment_percentage":
            if params.get("has_loans") == "No":
                 if params.get(key) != "N/A":
                     params[key] = "N/A"
                 continue 
            elif params.get("has_loans") is None:
                 continue

        # Check if the parameter is missing
        if params.get(key) is None:
            next_question_key = key
            break 

    # --- 3. Ask the next question OR Calculate score ---
    if next_question_key:
        question_text, options = QUESTIONS[next_question_key]
        response += f"{question_text} Options: [{', '.join(options)}]"
        state["last_agent"] = "UserProfileAgent"
        state["pending_question"] = next_question_key
        logger.info(f"User {user_id}: Asking next profile question for '{next_question_key}'")
    else:
        logger.info(f"User {user_id}: All profile parameters collected. Calculating risk score.")
        total_score, category, individual_scores = calculate_risk_score(params)

        if total_score is not None and category is not None:
            profile["risk_score"] = total_score
            profile["risk_category"] = category
            profile["risk_calculation_details"] = individual_scores
            logger.info(f"User {user_id}: Risk score calculated: {total_score}, Category: {category}")
            response += (f"Thank you! I've assessed your financial profile based on your answers. "
                         f"Your Financial Stability Score is {total_score}/100, placing you in the '{category}' category. "
                         f"This helps understand your capacity for investment risk. "
                         f"Would you like portfolio suggestions based on this?")
            state["last_agent"] = None
            state["pending_question"] = None
            state["context"] = {}
        else:
             logger.error(f"User {user_id}: calculate_risk_score returned None even after checking all params. Params: {params}")
             response += "It seems I have all your answers, but there was an issue calculating the score. Let's try again later or check the inputs."
             state["last_agent"] = None
             state["pending_question"] = None 

    return response, user_data