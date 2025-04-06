from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse
import logging
import os
from fastapi.staticfiles import StaticFiles
from data.db_config import engine
from src.models.community_models import Base
from src.api.community_routes import router as community_router
from src.api import news_routes  
from src.api import investment_routes 

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# FastAPI app
app = FastAPI(
    title="GenAI Financial Assistant API",
    description="API for the GenAI Financial Assistant for India",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


from src.api.chat_routes import process_chat
from src.api.webhook_routes import process_whatsapp_webhook

# Register the route functions
app.post("/api/chat")(process_chat)
app.post("/api/webhook/whatsapp")(process_whatsapp_webhook)

# Create media directories if they don't exist
os.makedirs("media/uploads/profiles", exist_ok=True)
os.makedirs("media/uploads/posts", exist_ok=True)

# Mount static files
app.mount("/media", StaticFiles(directory="media"), name="media")

# Include the routers
app.include_router(news_routes.router)
app.include_router(investment_routes.router)
app.include_router(community_router)

# Root path handler to provide API information
@app.get("/")
async def root():
    return {
        "status": "online",
        "service": "GenAI Financial Assistant API",
        "documentation": "/docs",
        "endpoints": [
            "/api/health",
            "/api/chat",
            "/api/webhook/whatsapp",
            "/api/investments", 
            "/docs",
            "/redoc"
        ]
    }

# Redirect /api to documentation
@app.get("/api")
async def api_redirect():
    return RedirectResponse(url="/docs")

@app.get("/api/health")
async def health_check():
    return {"status": "OK"}

# Error handler for 404 errors
@app.exception_handler(404)
async def custom_404_handler(request, exc):
    return {
        "detail": "Not Found",
        "available_endpoints": [
            "/",
            "/api/health",
            "/api/chat",
            "/api/webhook/whatsapp",
            "/api/investments", 
            "/docs",
            "/redoc"
        ]
    }

# Initialize database
try:
    Base.metadata.create_all(bind=engine)
    logger.info("Database tables created successfully")
except Exception as e:
    logger.error(f"Error creating database tables: {str(e)}")

# Add request logging middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    logger.info(f"Request: {request.method} {request.url}")
    response = await call_next(request)
    logger.info(f"Response status: {response.status_code}")
    return response