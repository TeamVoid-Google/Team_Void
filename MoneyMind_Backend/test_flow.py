import sys
import os
import logging
import uvicorn
from config import settings
from pyngrok import ngrok

# --- Setup Project Path ---
project_root = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, project_root)

# --- Configure Logging (Optional but helpful) ---
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("TestFlowScript")

# --- Import the Core Logic ---
try:
    from src.agents.main_agent import route_request
    from src.data_manager.json_manager import json_manager 
    from src.api.webhook_routes import app
    logger.info("Successfully imported core modules.")
except ImportError as e:
    logger.error(f"Error importing modules. Make sure you are in the project root directory and venv is active.")
    logger.error(f"ImportError: {e}")
    sys.exit(1)
except Exception as e:
    logger.error(f"An unexpected error occurred during import: {e}")
    sys.exit(1)

# --- Function to Start Ngrok ---
def start_ngrok():
    """Start ngrok and return the public URL."""
    try:
        ngrok.set_auth_token(settings.Ngrok_AUTHTOKEN)
        public_url = ngrok.connect(5000).public_url
        print(f"* Ngrok tunnel URL: {public_url}")
        return public_url
    except Exception as e:
        logger.error(f"Failed to start ngrok tunnel: {e}")
        print(f"Error: Could not start ngrok tunnel. WhatsApp integration will not work. Error: {e}")
        return None
    

def run_test_conversation():
    """Runs a command-line loop to test the agent flow."""
    test_user_id = "local_test_user" 
    user_data_file = json_manager._get_user_filepath(test_user_id) 
    start_ngrok()
    logger.info(f"Starting test conversation for user_id: '{test_user_id}'")
    logger.info(f"User data will be stored/read from: {user_data_file}")
    print("\n--- GenAI Financial Assistant Test ---")
    print(f"Testing with user ID: {test_user_id}")
    print("Type 'quit' or 'exit' to end the session.")
    print("---------------------------------------\n")


    try:
        pass
    except Exception as e:
         logger.error(f"Error during initial setup: {e}")


    while True:
        try:
            user_message = input("You: ")
            if user_message.lower() in ['quit', 'exit']:
                break

            if not user_message:
                continue

            # --- Call the Main Agent Orchestrator ---
            logger.info(f"Calling route_request for '{test_user_id}' with message: '{user_message}'")
            assistant_response = route_request(test_user_id, user_message)

            print(f"\nMoneyMind: {assistant_response}\n")
            logger.info(f"Received response: '{assistant_response[:100]}...'")

        except KeyboardInterrupt:
            print("\nExiting test session.")
            break
        except Exception as e:
            logger.error(f"An error occurred during the conversation loop: {e}", exc_info=True)
            print(f"\nSYSTEM_ERROR: An error occurred: {e}\n")

    # --- Cleanup ---
    print("\n--- Test Session Ended ---")
    cleanup = input(f"Do you want to delete the test data file ({user_data_file})? (yes/no): ")
    if cleanup.lower() == 'yes':
        try:
            if os.path.exists(user_data_file):
                os.remove(user_data_file)
                print(f"Deleted {user_data_file}")
                logger.info(f"Deleted test data file: {user_data_file}")
            else:
                print("Test data file not found (already deleted or never created).")
        except Exception as e:
            logger.error(f"Error deleting test data file: {e}")
            print(f"Error deleting file: {e}")
    else:
         print("Keeping test data file.")


if __name__ == "__main__":
    try:
         from config import settings
         if not settings.GEMINI_API_KEY or not settings.SERPAPI_API_KEY:
              logger.warning("API Keys might be missing in .env file. Functionality may be limited.")
    except Exception as e:
         logger.error(f"Could not verify settings: {e}")

    run_test_conversation()