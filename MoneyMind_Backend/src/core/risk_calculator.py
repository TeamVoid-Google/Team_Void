import logging

logger = logging.getLogger(__name__)

def calculate_risk_score(parameters: dict) -> tuple[int | None, str | None, dict | None]:
    """
    Calculates the risk score and category based on user parameters.

    Args:
        parameters: A dictionary containing user answers to risk questions.

    Returns:
        A tuple containing: (total_score, risk_category, individual_scores)
        Returns (None, None, None) if any required parameter is missing.
    """
    scores = {}
    total_score = 0
    all_params_filled = True

    # --- Score Mapping ---
    score_map = {
        "income_source": {"Salary": 10, "Business": 5, "Investments": 5, "Others": 0, None: 0},
        "income_stability": {"Very stable": 10, "Somewhat stable": 5, "Unstable": 0, None: 0},
        "savings_percentage": {"More than 30%": 10, "10-30%": 5, "Less than 10%": 0, None: 0},
        "has_loans": {"No": 10, "Yes, but manageable": 5, "Yes, multiple loans": 0, None: 0},
        "loan_payment_percentage": {"Less than 20%": 10, "20-50%": 5, "More than 50%": 0, "N/A": 10, None: 0},
        "credit_usage_frequency": {"Rarely": 10, "Sometimes": 5, "Often": 0, None: 0},
        "investment_preference": {"Fixed Deposits & Savings": 10, "Mutual Funds & Stocks": 5, "High-risk investments": 0, None: 0},
        "reaction_to_loss": {"Invest more": 10, "Wait and watch": 5, "Sell immediately": 0, None: 0},
        "emergency_fund": {"Yes": 10, "No": 0, None: 0},
        "missed_payments": {"No": 10, "Yes": 0, None: 0}
    }

    # --- Question Key Mapping ---
    q_map = {
        "income_source": "q1", "income_stability": "q2", "savings_percentage": "q3",
        "has_loans": "q4", "loan_payment_percentage": "q5", "credit_usage_frequency": "q6",
        "investment_preference": "q7", "reaction_to_loss": "q8", "emergency_fund": "q9",
        "missed_payments": "q10"
    }

    # --- Process Parameters ---
    has_loans_answer = parameters.get("has_loans")
    if has_loans_answer == "No" and parameters.get("loan_payment_percentage") is None:
        parameters["loan_payment_percentage"] = "N/A" 

    for i, (param, mapping) in enumerate(score_map.items()):
        value = parameters.get(param)
        q_key = q_map.get(param, f"q_unknown_{i+1}")

        if value is None:
            if not (param == "loan_payment_percentage" and has_loans_answer == "No"):
                all_params_filled = False
                logger.warning(f"Risk Calculation: Missing required parameter '{param}'.")
                # Assign 0 score but mark as incomplete
                score = 0
            else:
                 score = 10 
        # Check if value is valid
        elif value not in mapping:
            logger.warning(f"Risk Calculation: Unexpected value '{value}' for parameter '{param}'. Assigning score 0.")
            score = 0
            all_params_filled = False 
        else:
            score = mapping[value]

        scores[q_key] = score
        total_score += score

    # --- Final Check and Category Assignment ---
    if not all_params_filled:
        logger.info("Risk Calculation: Not all parameters filled. Score calculation aborted.")
        return None, None, None 

    # Ensure score is within 0-100 range 
    total_score = max(0, min(100, total_score))

    if total_score >= 80:
        category = "High Risk Tolerance"
    elif total_score >= 50:
        category = "Moderate Risk Tolerance"
    else:
        category = "Low Risk Tolerance"

    logger.info(f"Risk Calculation Complete: Score={total_score}, Category='{category}'")
    return total_score, category, scores