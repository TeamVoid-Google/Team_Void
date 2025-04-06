import sys
import os
from config import settings
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..')))

from fastapi import APIRouter, Request, Form
from fastapi.responses import PlainTextResponse
from twilio.rest import Client
import logging
import requests
import pytesseract
from PIL import Image
from io import BytesIO
from src.agents.main_agent import route_request
from src.data_manager.json_manager import json_manager

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("webhook.log")
    ]
)
logger = logging.getLogger(__name__)

router = APIRouter()

# Twilio credentials
account_sid = settings.Twilio_Account_SID
auth_token = settings.Twilio_Auth_Token
client = Client(account_sid, auth_token)

async def send_whatsapp_message(to_number: str, message: str) -> bool:
    """
    Send a message to the user via WhatsApp using Twilio, ensuring it's within 1600 characters.
    """
    try:
        if len(message) > 1600:
            truncated_message = message[:1570] + "... (truncated due to length)"
            logger.warning(f"Message truncated from {len(message)} to 1600 characters")
            message = truncated_message
        
        message_obj = client.messages.create(
            body=message,
            from_='whatsapp:+14155238886',
            to=f'whatsapp:{to_number}'
        )
        logger.info(f"Message sent successfully! SID: {message_obj.sid}")
        return True
    except Exception as e:
        logger.error(f"Error sending message: {str(e)}")
        return False

async def process_text(user_id: str, user_message: str, from_number: str) -> str:
    try:
        logger.info(f"Received message from {from_number}: {user_message}")
        response, updated_user_data = route_request(user_id, user_message)
        json_manager.save_user_data(user_id, updated_user_data)

        response_parts = updated_user_data.get("response_parts", [response])
        for part in response_parts:
            if part.lower() == "exit":
                await send_whatsapp_message(from_number, "Thank you for using MoneyMind. Goodbye!")
                return "OK"
            redirect_conditions = ["/portfolio", "/profile", "/generate_portfolio"]
            if any(user_message.lower().startswith(cmd) for cmd in redirect_conditions):
                app_link = "https://your-app-url.com"
                redirect_message = f"This feature is best accessed in our app. Please visit: {app_link} to continue."
                await send_whatsapp_message(from_number, redirect_message)
                return "OK"
            if await send_whatsapp_message(from_number, part):
                logger.info(f"Response part sent successfully to {from_number}: {part[:50]}...")
            else:
                logger.error(f"Failed to send response part to {from_number}: {part[:50]}...")
    except Exception as e:
        logger.error(f"Error processing text: {str(e)}")
        await send_whatsapp_message(from_number, f"Error processing your request: {str(e)}")
    return "OK"

async def process_image(user_id: str, media_url: str, from_number: str) -> str:
    """
    Process an image sent by the user, perform OCR, and use route_request for response.
    """
    try:
        logger.info(f"Processing image from {from_number}: {media_url}")
        response = requests.get(media_url, auth=(account_sid, auth_token))
        if response.status_code != 200:
            await send_whatsapp_message(from_number, f"Failed to download image. Status: {response.status_code}")
            return "OK"
        img = Image.open(BytesIO(response.content))
        extracted_text = pytesseract.image_to_string(img)
        logger.info(f"Extracted text: {extracted_text}")
        if not extracted_text.strip():
            await send_whatsapp_message(from_number, "No text found in the image.")
            return "OK"
        response, updated_user_data = route_request(user_id, extracted_text)
        json_manager.save_user_data(user_id, updated_user_data)
        if response.lower() == "exit":
            await send_whatsapp_message(from_number, "Thank you for using MoneyMind. Goodbye!")
            return "OK"
        if await send_whatsapp_message(from_number, response):
            logger.info("Response sent successfully!")
        else:
            logger.error("Failed to send response!")
    except Exception as e:
        logger.error(f"Error processing image: {str(e)}")
        await send_whatsapp_message(from_number, f"Error processing image: {str(e)}")
    return "OK"

@router.post("/webhook", response_class=PlainTextResponse)
async def process_whatsapp_webhook(
    request: Request,
    From: str = Form(default=''),
    Body: str = Form(default=''),
    MediaUrl0: str = Form(default='')
):
    logger.info("\n--- New Webhook Request ---")
    logger.info(f"Form data: {await request.form()}")
    from_number = From.replace('whatsapp:', '')
    if not from_number:
        logger.error("No 'From' number provided in request")
        return "OK"
    user_id = from_number
    if MediaUrl0:
        logger.info(f"Processing image: {MediaUrl0}")
        return await process_image(user_id, MediaUrl0, from_number)
    elif Body:
        logger.info(f"Processing text: {Body}")
        return await process_text(user_id, Body, from_number)
    else:
        await send_whatsapp_message(from_number, "Please send a text message or an image to get started.")
        return "OK"