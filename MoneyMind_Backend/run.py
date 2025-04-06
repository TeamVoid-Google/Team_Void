import sys
import os
import uvicorn
import logging

project_root = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, project_root)

from src.app import app
from src.api.investment_routes import router as investment_router

app.include_router(investment_router)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

if __name__ == '__main__':
    logger.info("Starting FastAPI development server using run.py...")
    
    port = int(os.environ.get("PORT", 8000))
    
    is_dev = os.environ.get("ENVIRONMENT", "development") == "development"
    
    uvicorn.run(
        "src.app:app", 
        host="0.0.0.0", 
        port=port, 
        reload=is_dev
    )