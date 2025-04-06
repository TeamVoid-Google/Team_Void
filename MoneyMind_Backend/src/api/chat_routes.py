from fastapi import APIRouter, HTTPException
import logging
from src.agents.main_agent import route_request
from pydantic import BaseModel
from typing import Optional

logger = logging.getLogger(__name__)

# FastAPI router
router = APIRouter()

# Define request model
class ChatRequest(BaseModel):
    user_id: str = "default_user"
    message: str

@router.post("/api/chat")
async def process_chat(chat_request: ChatRequest):
    """
    Endpoint to process chat messages from the Flutter app
    """
    try:
        if not chat_request.message:
            raise HTTPException(status_code=400, detail="Message cannot be empty")
        
        response = route_request(chat_request.user_id, chat_request.message)
        
        return {
            "response": response,
            "status": "success"
        }
    except Exception as e:
        logger.error(f"Error in chat endpoint: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))