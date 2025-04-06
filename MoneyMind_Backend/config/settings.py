import os
from dotenv import load_dotenv
import logging

load_dotenv()

# --- API Keys ---
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
SERPAPI_API_KEY = os.getenv("SERPAPI_API_KEY")
Twilio_Account_SID=os.getenv("Twilio_Account_SID")
Twilio_Auth_Token=os.getenv("Twilio_Auth_Token")
Ngrok_AUTHTOKEN=os.getenv("Ngrok_AUTHTOKEN")

# --- Database Configuration ---
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://moneymind_user:LiAPP7sBct8LZjLacQDJEMhNHc7wY2zc@dpg-cvnormre5dus73d1sqqg-a/moneymind")

# Render PostgreSQL URL format
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

# --- Application Settings ---
DATA_DIR = "data"
DEFAULT_USER_ID = "default_user"

# --- Logging Configuration ---
logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# --- Model Selection ---
GEMINI_FAST_MODEL = 'gemini-1.5-flash'

# --- Basic Validation ---
if not GEMINI_API_KEY:
    logger.error("GEMINI_API_KEY not found in environment variables.")
if not SERPAPI_API_KEY:
    logger.error("SERPAPI_API_KEY not found in environment variables.")
if not Twilio_Account_SID:
    logger.error("Twilio_Account_SID not found in environment variables.")
if not Twilio_Auth_Token:
    logger.error("Twilio_Auth_Token not found in environment variables.")
if not Ngrok_AUTHTOKEN:
    logger.error("Ngrok_AUTHTOKEN not found in environment variables.")

# --- Default User Structure ---
DEFAULT_USER_STRUCTURE = {
  "user_id": None,
  "profile": {
    "name": None,
    "risk_parameters": {
      "income_source": None,
      "income_stability": None,
      "savings_percentage": None,
      "has_loans": None,
      "loan_payment_percentage": None,
      "credit_usage_frequency": None,
      "investment_preference": None,
      "reaction_to_loss": None,
      "emergency_fund": None,
      "missed_payments": None
    },
    "risk_score": None,
    "risk_category": None
  },
  "preferences": {
    "liked_companies": [],
    "liked_investment_types": [],
    "news_interaction_topics": [],
    "qna_topics_interest": []
  },
  "history": {
    "qna_log": [],
    "news_log": [],
    "portfolio_suggestions": []
  },
  "conversation_state": {
    "last_agent": None,
    "pending_question": None, 
    "context": {}
  }
}

# --- Community Settings ---
MEDIA_STORAGE_PATH = "media/uploads"
MAX_IMAGE_SIZE_MB = 5
ALLOWED_IMAGE_EXTENSIONS = ["jpg", "jpeg", "png", "gif"]
POSTS_PER_PAGE = 10