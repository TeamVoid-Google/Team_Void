import logging
from config import settings
import requests
import json

logger = logging.getLogger(__name__)

# --- Configuration (Adapt for your provider) ---
# Example for Meta Cloud API:
META_API_VERSION = "v18.0" 
META_BOT_PHONE_ID = settings.META_BOT_PHONE_ID 
META_ACCESS_TOKEN = settings.META_ACCESS_TOKEN 
META_API_URL = f"https://graph.facebook.com/{META_API_VERSION}/{META_BOT_PHONE_ID}/messages"

# --- Send Function ---
def send_whatsapp_message(recipient_phone: str, message_text: str) -> bool:
    """
    Sends a message back to the user via the configured WhatsApp provider.

    Args:
        recipient_phone: The user's phone number (format depends on provider,
                         e.g., '911234567890' for Meta, 'whatsapp:+91...' for Twilio).
        message_text: The text message to send.

    Returns:
        True if the message was sent successfully (or queued), False otherwise.
    """
    logger.info(f"Preparing to send WhatsApp to {recipient_phone}")

    # --- Implementation for Meta Cloud API ---
    if META_BOT_PHONE_ID and META_ACCESS_TOKEN:
        headers = {
            "Authorization": f"Bearer {META_ACCESS_TOKEN}",
            "Content-Type": "application/json",
        }
        payload = {
            "messaging_product": "whatsapp",
            "to": recipient_phone, 
            "type": "text",
            "text": {
                "preview_url": False,
                "body": message_text,
            }
        }
        try:
            response = requests.post(META_API_URL, headers=headers, json=payload)
            response.raise_for_status() 
            response_data = response.json()
            logger.info(f"Message sent via Meta API. Response: {response_data}")
            return True
        except requests.exceptions.RequestException as e:
            logger.error(f"Error sending message via Meta API: {e}")
            logger.error(f"Response Status: {e.response.status_code if e.response else 'N/A'}")
            logger.error(f"Response Body: {e.response.text if e.response else 'N/A'}")
            return False
        except Exception as e:
             logger.error(f"Unexpected error during Meta API send: {e}")
             return False
    else:
        logger.warning("WhatsApp provider (Meta or Twilio) not fully configured. Cannot send message.")
        # --- Fallback Simulation ---
        print("-" * 20)
        print(f"SIMULATING WHATSAPP SEND to {recipient_phone}:")
        print(message_text)
        print("-" * 20)
        return True 