# services/investment_service.py
import os
import logging
import json
from typing import List, Dict, Any, Optional
import google.generativeai as genai
from serpapi import GoogleSearch
from fastapi import Depends, HTTPException, BackgroundTasks
from pydantic import BaseModel, Field

logger = logging.getLogger(__name__)

class InvestmentCriteria(BaseModel):
    categories: List[str] = Field(default=[])
    risk_tolerance: str = Field(default="Low")
    time_horizon: str = Field(default="1 year")
    investment_amount: float = Field(default=10000.0)
    tax_free_growth: bool = Field(default=True)
    goal: Optional[str] = Field(default=None)
    user_id: Optional[str] = Field(default=None)

class ProductComparison(BaseModel):
    product_ids: List[str] = Field(...)
    factors: List[str] = Field(default=["return", "risk", "fees", "liquidity", "tax_efficiency"])
    user_id: Optional[str] = Field(default=None)

class InvestmentProductAI:
    def __init__(self):
        self.gemini_api_key = os.getenv("GEMINI_API_KEY")
        self.serpapi_api_key = os.getenv("SERPAPI_API_KEY")
        self.product_cache = {}
        self.setup_gemini()
        
    def setup_gemini(self):
        """Configure Gemini API"""
        genai.configure(api_key=self.gemini_api_key)
        self.model = genai.GenerativeModel('gemini-1.5-flash')
        
    async def recommend_products(self, criteria: InvestmentCriteria) -> List[Dict[str, Any]]:
        """
        Get personalized product recommendations based on user criteria.
        """
        base_products = await self._fetch_relevant_products(criteria)
        
        if not base_products:
            logger.warning("No base products found for criteria: %s", criteria)
            return []
            
        prompt = self._build_recommendation_prompt(criteria, base_products)
        response = await self._generate_response(prompt)
        
        try:
            enhanced_products = self._parse_recommendations(response, base_products)
            return enhanced_products
        except Exception as e:
            logger.error("Failed to process recommendations: %s", str(e))
            return base_products
        
    async def compare_products(self, comparison: ProductComparison) -> Dict[str, Any]:
        """
        Generate detailed comparison between selected products.
        """
        products = []
        for product_id in comparison.product_ids:
            try:
                product = await self._fetch_product_details(product_id)
                products.append(product)
            except Exception as e:
                logger.error(f"Error fetching product {product_id}: {str(e)}")
        
        if len(products) < 2:
            raise HTTPException(status_code=400, detail="At least two valid products are required for comparison")
            
        prompt = self._build_comparison_prompt(products, comparison.factors)
        response = await self._generate_response(prompt)
        
        try:
            comparison_data = self._parse_comparison(response, products)
            return comparison_data
        except Exception as e:
            logger.error(f"Failed to process comparison: {str(e)}")
            return self._generate_basic_comparison(products, comparison.factors)
    
    async def explain_benefits(self, product_id: str, user_id: Optional[str] = None) -> str:
        """
        Explain why a specific product is beneficial for the user's situation.
        """
        product = await self._fetch_product_details(product_id)
        
        user_context = {}
        if user_id:
            user_context = await self._fetch_user_context(user_id)
            
        # Generate personalized explanation
        prompt = self._build_benefits_prompt(product, user_context)
        response = await self._generate_response(prompt)
        return response
    
    async def _fetch_relevant_products(self, criteria: InvestmentCriteria) -> List[Dict[str, Any]]:
        """Fetch relevant investment products based on criteria"""
        search_terms = []
        
        if criteria.categories:
            search_terms.extend(criteria.categories)
        
        search_terms.append(criteria.risk_tolerance.lower() + " risk")
        search_terms.append(criteria.time_horizon)
        
        if criteria.tax_free_growth:
            search_terms.append("tax free")
            
        search_query = " ".join(search_terms)
        
        try:
            params = {
                "engine": "google_shopping",
                "q": search_query + " investment",
                "api_key": self.serpapi_api_key
            }
            
            search = GoogleSearch(params)
            results = search.get_dict()
            
            if "shopping_results" in results:
                products = []
                for item in results.get("shopping_results", [])[:5]:
                    product = {
                        "id": item.get("product_id", ""),
                        "name": item.get("title", ""),
                        "type": self._categorize_product(item),
                        "return": self._estimate_return(item),
                        "risk": criteria.risk_tolerance,
                        "timeHorizon": criteria.time_horizon,
                        "expenseRatio": self._extract_expense_ratio(item),
                        "minInvestment": self._extract_min_investment(item),
                        "price": item.get("price", ""),
                        "rating": item.get("rating", 0),
                        "taxAdvantaged": criteria.tax_free_growth,
                    }
                    products.append(product)
                return products
            
            return []
            
        except Exception as e:
            logger.error(f"Error fetching products: {str(e)}")
            return []
    
    def _categorize_product(self, item: Dict[str, Any]) -> str:
        """Determine product category from search result"""
        title = item.get("title", "").lower()
        
        if "etf" in title:
            return "ETF"
        elif "bond" in title:
            return "Bonds"
        elif "gold" in title:
            return "Gold"
        elif "silver" in title:
            return "Silver"
        elif "ipo" in title:
            return "IPO's"
        elif "mutual fund" in title:
            return "Mutual Funds"
        elif "deposit" in title:
            return "Fixed Deposit"
        elif "crypto" in title or "bitcoin" in title:
            return "Crypto"
        else:
            return "Stocks"
    
    def _estimate_return(self, item: Dict[str, Any]) -> str:
        """Estimate return percentage based on product type"""
        category = self._categorize_product(item)
        
        return_mapping = {
            "ETF": "9.5%",
            "Stocks": "10.2%",
            "Bonds": "5.1%",
            "Gold": "7.8%",
            "Silver": "7.2%",
            "IPO's": "12.8%",
            "Mutual Funds": "8.7%",
            "Fixed Deposit": "4.5%",
            "Crypto": "15.4%",
        }
        
        return return_mapping.get(category, "8.0%")
    
    def _extract_expense_ratio(self, item: Dict[str, Any]) -> str:
        """Extract expense ratio or provide an estimate"""
        category = self._categorize_product(item)
        
        expense_mapping = {
            "ETF": "0.05%",
            "Stocks": "0.00%",
            "Bonds": "0.25%",
            "Gold": "0.25%",
            "Silver": "0.50%",
            "IPO's": "0.60%",
            "Mutual Funds": "0.75%",
            "Fixed Deposit": "0.00%",
            "Crypto": "1.00%",
        }
        
        return expense_mapping.get(category, "0.50%")
    
    def _extract_min_investment(self, item: Dict[str, Any]) -> str:
        """Extract minimum investment or provide an estimate"""
        price = item.get("extracted_price", 0)
        if price:
            return f"${price}"
        
        category = self._categorize_product(item)
        min_investment_mapping = {
            "ETF": "$50",
            "Stocks": "$1",
            "Bonds": "$1000", 
            "Gold": "$50",
            "Silver": "$25",
            "IPO's": "$500",
            "Mutual Funds": "$1000",
            "Fixed Deposit": "$500",
            "Crypto": "$10",
        }
        
        return min_investment_mapping.get(category, "$100")
        
    async def _fetch_product_details(self, product_id: str) -> Dict[str, Any]:
        """Fetch detailed information about a specific product"""
        if product_id in self.product_cache:
            return self.product_cache[product_id]
            
        try:
            params = {
                "engine": "google_product",
                "product_id": product_id,
                "api_key": self.serpapi_api_key
            }
            
            search = GoogleSearch(params)
            results = search.get_dict()
            
            if "product_results" in results:
                product_data = results["product_results"]
                
                product = {
                    "id": product_id,
                    "name": product_data.get("title", ""),
                    "type": self._infer_product_type(product_data),
                    "return": self._infer_return(product_data),
                    "risk": self._infer_risk_level(product_data),
                    "timeHorizon": self._infer_time_horizon(product_data),
                    "expenseRatio": self._infer_expense_ratio(product_data),
                    "minInvestment": self._infer_min_investment(product_data),
                    "price": product_data.get("price", ""),
                    "description": product_data.get("description", ""),
                    "rating": product_data.get("rating", 0),
                    "reviews": product_data.get("reviews", 0),
                    "images": [img.get("link") for img in product_data.get("media", []) if img.get("type") == "image"][:3],
                    "highlights": product_data.get("highlights", []),
                    "specs": product_data.get("specs_results", {})
                }
                
                self.product_cache[product_id] = product
                return product
            
            raise HTTPException(status_code=404, detail=f"Product not found: {product_id}")
            
        except Exception as e:
            logger.error(f"Error fetching product details: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Failed to retrieve product: {str(e)}")
    
    def _infer_product_type(self, product_data: Dict[str, Any]) -> str:
        """Infer product type from product data"""
        title = product_data.get("title", "").lower()
        
        if "etf" in title:
            return "ETF"
        elif "bond" in title:
            return "Bonds"
        elif "gold" in title:
            return "Gold"
        elif "silver" in title:
            return "Silver"
        elif "ipo" in title:
            return "IPO's"
        
        return "ETF"
    
    def _infer_return(self, product_data: Dict[str, Any]) -> str:
        """Infer estimated return from product data"""
        return "8.5%"
    
    def _infer_risk_level(self, product_data: Dict[str, Any]) -> str:
        """Infer risk level from product data"""
        title = product_data.get("title", "").lower()
        description = product_data.get("description", "").lower()
        
        if "bond" in title or "treasury" in title or "low risk" in description:
            return "Low"
        elif "growth" in title or "moderate risk" in description:
            return "Moderate"
        elif "high growth" in title or "aggressive" in title:
            return "High"
            
        return "Moderate" 
    
    def _infer_time_horizon(self, product_data: Dict[str, Any]) -> str:
        """Infer recommended time horizon from product data"""
        description = product_data.get("description", "").lower()
        
        if "short term" in description or "1 year" in description:
            return "1 year"
        elif "medium term" in description or "2-3" in description:
            return "2-3 years"
        elif "long term" in description or "5+" in description:
            return "5+ years"
            
        return "2-3 years"  
    
    def _infer_expense_ratio(self, product_data: Dict[str, Any]) -> str:
        """Infer expense ratio from product data"""
        product_type = self._infer_product_type(product_data)
        
        expense_mapping = {
            "ETF": "0.05%",
            "Stocks": "0.00%",
            "Bonds": "0.25%",
            "Gold": "0.25%",
            "Silver": "0.50%",
            "IPO's": "0.60%",
            "Mutual Funds": "0.75%",
            "Fixed Deposit": "0.00%",
            "Crypto": "1.00%",
        }
        
        return expense_mapping.get(product_type, "0.50%")
    
    def _infer_min_investment(self, product_data: Dict[str, Any]) -> str:
        """Infer minimum investment from product data"""
        price = product_data.get("price", "")
        if price and isinstance(price, str) and price.startswith("$"):
            try:
                return price
            except:
                pass
                
        product_type = self._infer_product_type(product_data)
        min_investment_mapping = {
            "ETF": "$50",
            "Stocks": "$1",
            "Bonds": "$1000", 
            "Gold": "$50",
            "Silver": "$25",
            "IPO's": "$500",
            "Mutual Funds": "$1000",
            "Fixed Deposit": "$500",
            "Crypto": "$10",
        }
        
        return min_investment_mapping.get(product_type, "$100")
    
    async def _fetch_user_context(self, user_id: str) -> Dict[str, Any]:
        """Fetch user context for personalized recommendations"""
        return {
            "risk_profile": "Moderate",
            "investment_goals": ["Retirement", "Growth"],
            "previous_investments": ["ETFs", "Stocks"],
            "age_group": "30-40"
        }
    
    async def _generate_response(self, prompt: str) -> str:
        """Generate response from the Gemini model"""
        try:
            response = await self.model.generate_content_async(prompt)
            return response.text
        except Exception as e:
            logger.error(f"Error generating AI response: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Failed to generate response: {str(e)}")
    
    def _build_recommendation_prompt(self, criteria: InvestmentCriteria, base_products: List[Dict[str, Any]]) -> str:
        """Build prompt for product recommendations"""
        products_str = json.dumps(base_products, indent=2)
        
        return f"""
        You are a financial advisor helping a client find investment products.
        
        Client's investment criteria:
        - Categories of interest: {', '.join(criteria.categories)}
        - Risk tolerance: {criteria.risk_tolerance}
        - Time horizon: {criteria.time_horizon}
        - Investment amount: ${criteria.investment_amount:,.2f}
        - Requires tax-free growth: {"Yes" if criteria.tax_free_growth else "No"}
        - Investment goal: {criteria.goal or 'Not specified'}
        
        I have found these potential investment products:
        {products_str}
        
        Based on the client's criteria and these products:
        1. Rank these products from most to least suitable for the client
        2. For each product, explain why it matches or doesn't match the client's needs
        3. Add any missing information to make these recommendations more helpful
        4. Suggest a recommended allocation percentage for each product
        
        Format your response as a JSON array of objects with these fields:
        - id: the product ID
        - name: the product name
        - type: the product type/category
        - return: expected return percentage
        - risk: risk level (Low/Moderate/High)
        - timeHorizon: recommended time horizon
        - expenseRatio: expense ratio percentage
        - minInvestment: minimum investment amount
        - match_score: a score from 1-100 indicating how well it matches the client's criteria
        - allocation: recommended allocation percentage (should sum to 100%)
        - reasoning: explanation of why this product is suitable
        - pros: list of advantages of this product for the client
        - cons: list of disadvantages of this product for the client
        """
    
    def _parse_recommendations(self, response: str, base_products: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Parse the AI response into structured recommendations"""
        try:
            json_start = response.find('[')
            json_end = response.rfind(']') + 1
            
            if json_start >= 0 and json_end > json_start:
                json_str = response[json_start:json_end]
                recommendations = json.loads(json_str)
                
                validated_recs = []
                for rec in recommendations:
                    if 'id' in rec and 'name' in rec:
                        validated_recs.append(rec)
                
                if validated_recs:
                    return validated_recs
            
            logger.warning("Could not parse AI recommendations, using base products")
            return base_products
            
        except Exception as e:
            logger.error(f"Error parsing recommendations: {str(e)}")
            return base_products
    
    def _build_comparison_prompt(self, products: List[Dict[str, Any]], factors: List[str]) -> str:
        """Build prompt for product comparison"""
        products_str = json.dumps(products, indent=2)
        factors_str = ", ".join(factors)
        
        return f"""
        As a financial advisor, I need to compare these investment products:
        {products_str}
        
        Please compare these products based on these factors: {factors_str}
        
        For each product, provide:
        1. A brief overview
        2. Strengths and weaknesses
        3. Ideal investor profile
        
        Then create a detailed comparison across all factors.
        
        Format your response as a JSON object with these sections:
        - products: an array of the enhanced product objects with additional analysis
        - comparison_table: a mapping of factors to comparisons across all products
        - overall_analysis: text summarizing the key differences
        - best_for: categories of investors and which product is best for them
        """
    
    def _parse_comparison(self, response: str, products: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Parse the AI response into structured comparison data"""
        try:
            json_start = response.find('{')
            json_end = response.rfind('}') + 1
            
            if json_start >= 0 and json_end > json_start:
                json_str = response[json_start:json_end]
                comparison_data = json.loads(json_str)
                
                if 'products' in comparison_data and 'comparison_table' in comparison_data:
                    return comparison_data
                
            logger.warning("Could not parse AI comparison, using basic comparison")
            return self._generate_basic_comparison(products)
            
        except Exception as e:
            logger.error(f"Error parsing comparison: {str(e)}")
            return self._generate_basic_comparison(products)
    
    def _generate_basic_comparison(self, products: List[Dict[str, Any]], factors: List[str] = None) -> Dict[str, Any]:
        """Generate a basic comparison when AI parsing fails"""
        if not factors:
            factors = ["return", "risk", "fees", "liquidity", "tax_efficiency"]
            
        # Create a simple comparison structure
        comparison_table = {}
        for factor in factors:
            comparison_table[factor] = {}
            for product in products:
                if factor == "return":
                    comparison_table[factor][product["name"]] = product.get("return", "N/A")
                elif factor == "risk":
                    comparison_table[factor][product["name"]] = product.get("risk", "N/A")
                elif factor == "fees":
                    comparison_table[factor][product["name"]] = product.get("expenseRatio", "N/A")
                else:
                    comparison_table[factor][product["name"]] = "No data"
        
        return {
            "products": products,
            "comparison_table": comparison_table,
            "overall_analysis": "Basic comparison of investment products. For a more detailed analysis, please try again.",
            "best_for": {"General investing": products[0]["name"] if products else "No recommendation"}
        }
    
    def _build_benefits_prompt(self, product: Dict[str, Any], user_context: Dict[str, Any]) -> str:
        """Build prompt for explaining product benefits"""
        product_str = json.dumps(product, indent=2)
        context_str = json.dumps(user_context, indent=2)
        
        return f"""
        As a financial advisor, explain why this investment product might be beneficial:
        {product_str}
        
        User context:
        {context_str}
        
        Please explain:
        1. How this product aligns with the user's risk profile and goals
        2. The key advantages of this product for this specific user
        3. Any potential drawbacks to be aware of
        4. What makes this product unique compared to alternatives
        5. How this product could fit into an overall investment strategy
        
        Your explanation should be clear, concise, and jargon-free. Focus on the practical benefits 
        and help the user understand why this product might be right for them.
        """