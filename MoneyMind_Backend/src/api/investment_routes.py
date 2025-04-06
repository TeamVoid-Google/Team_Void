# api/investment_routes.py
from typing import List, Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from pydantic import BaseModel, Field

from src.services.investment_service import InvestmentProductAI, InvestmentCriteria, ProductComparison
from ..services.investment_assistant_service import InvestmentAssistant, UserQuery

router = APIRouter(prefix="/api/investments", tags=["investments"])

# Initialize services
investment_service = InvestmentProductAI()
assistant_service = InvestmentAssistant()

# Request/Response Models
class InvestmentCriteriaRequest(BaseModel):
    categories: List[str] = Field(default=[])
    risk_tolerance: str = Field(default="Low")
    time_horizon: str = Field(default="1 year")
    investment_amount: float = Field(default=10000.0)
    tax_free_growth: bool = Field(default=True)
    goal: Optional[str] = Field(default=None)
    user_id: Optional[str] = Field(default=None)

class ProductIdRequest(BaseModel):
    product_id: str = Field(...)
    user_id: Optional[str] = Field(default=None)

class ComparisonRequest(BaseModel):
    product_ids: List[str] = Field(...)
    factors: List[str] = Field(default=["return", "risk", "fees", "liquidity", "tax_efficiency"])
    user_id: Optional[str] = Field(default=None)

class AssistantQueryRequest(BaseModel):
    question: str = Field(...)
    products: Optional[List[Dict[str, Any]]] = Field(default=None)
    user_id: Optional[str] = Field(default=None)
    conversation_history: Optional[List[Dict[str, str]]] = Field(default=None)

# Routes for investment products and recommendations
@router.post("/recommend", response_model=List[Dict[str, Any]])
async def recommend_products(criteria: InvestmentCriteriaRequest):
    """
    Get personalized investment product recommendations based on user criteria
    """
    try:
        internal_criteria = InvestmentCriteria(**criteria.dict())
        
        recommendations = await investment_service.recommend_products(internal_criteria)
        return recommendations
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get recommendations: {str(e)}")

@router.post("/products/explain", response_model=Dict[str, Any])
async def explain_product_benefits(request: ProductIdRequest):
    """
    Explain why a specific product might be beneficial for the user
    """
    try:
        explanation = await investment_service.explain_benefits(
            product_id=request.product_id,
            user_id=request.user_id
        )
        return {"explanation": explanation}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to explain product benefits: {str(e)}")

@router.post("/compare", response_model=Dict[str, Any])
async def compare_products(comparison: ComparisonRequest):
    """
    Generate a detailed comparison between selected products
    """
    try:
        internal_comparison = ProductComparison(**comparison.dict())
        
        comparison_data = await investment_service.compare_products(internal_comparison)
        return comparison_data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to compare products: {str(e)}")

# Routes for investment assistant
@router.post("/assistant/query", response_model=Dict[str, Any])
async def query_assistant(query: AssistantQueryRequest):
    """
    Get investment advice from the AI assistant
    """
    try:
        internal_query = UserQuery(
            question=query.question,
            products=query.products,
            user_id=query.user_id,
            conversation_history=query.conversation_history
        )
        
        response = await assistant_service.answer_question(internal_query)
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get answer: {str(e)}")

@router.post("/assistant/explain-product", response_model=Dict[str, Any])
async def explain_product_assistant(request: Dict[str, Any]):
    """
    Get AI assistant explanation of a product's benefits
    """
    try:
        product = request.get("product")
        user_id = request.get("user_id")
        
        if not product:
            raise HTTPException(status_code=400, detail="Product data is required")
            
        response = await assistant_service.explain_product_benefits(product, user_id)
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to explain product: {str(e)}")

@router.post("/assistant/compare-products", response_model=Dict[str, Any])
async def compare_products_assistant(request: Dict[str, Any]):
    """
    Get AI assistant comparison of multiple products
    """
    try:
        products = request.get("products", [])
        
        if not products or len(products) < 2:
            raise HTTPException(status_code=400, detail="At least two products are required for comparison")
            
        response = await assistant_service.compare_products_conversation(products)
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to compare products: {str(e)}")