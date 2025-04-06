# services/investment_assistant_service.py
import os
import logging
import json
from typing import List, Dict, Any, Optional
import google.generativeai as genai
from pydantic import BaseModel, Field

logger = logging.getLogger(__name__)

class UserQuery(BaseModel):
    question: str = Field(..., description="User's investment-related question")
    products: Optional[List[Dict[str, Any]]] = Field(default=None, description="Products being discussed")
    user_id: Optional[str] = Field(default=None, description="User ID for personalization")
    conversation_history: Optional[List[Dict[str, str]]] = Field(default=None, description="Previous conversation")

class InvestmentAssistant:
    def __init__(self):
        self.gemini_api_key = os.getenv("GEMINI_API_KEY")
        self.setup_gemini()
        
    def setup_gemini(self):
        """Configure Gemini API"""
        genai.configure(api_key=self.gemini_api_key)
        self.model = genai.GenerativeModel('gemini-1.5-flash')
    
    async def answer_question(self, query: UserQuery) -> Dict[str, Any]:
        """
        Answer user's investment-related questions using Gemini.
        """
        try:
            logger.info(f"Processing query: {query.question}")
            logger.debug(f"Full query data: {query}")
            
            user_context = {}
            if query.user_id:
                user_context = await self._fetch_user_context(query.user_id)
                
            prompt = self._build_answer_prompt(query, user_context)
            
            response = await self._generate_response(prompt)
            
            try:
                structured_response = self._parse_structured_response(response)
                return structured_response
            except Exception as e:
                logger.warning(f"Failed to parse structured response: {str(e)}")
                return {
                    "answer": response,
                    "follow_up_questions": [],
                    "resources": []
                }
                
        except Exception as e:
            logger.error(f"Error answering question: {str(e)}", exc_info=True)
            return {
                "answer": f"I'm sorry, I couldn't process your question due to a technical issue. Please try asking in a different way.",
                "follow_up_questions": [],
                "resources": []
            }
    
    async def explain_product_benefits(self, product: Dict[str, Any], user_id: Optional[str] = None) -> Dict[str, Any]:
        """
        Explain the benefits of a specific investment product.
        """
        try:
            user_context = {}
            if user_id:
                user_context = await self._fetch_user_context(user_id)
                
            prompt = self._build_benefits_prompt(product, user_context)
            
            response = await self._generate_response(prompt)
            
            try:
                structured_response = self._parse_benefits_response(response)
                return structured_response
            except Exception as e:
                logger.warning(f"Failed to parse benefits response: {str(e)}")
                return {
                    "summary": response,
                    "benefits": [],
                    "considerations": [],
                    "ideal_for": ""
                }
                
        except Exception as e:
            logger.error(f"Error explaining product benefits: {str(e)}")
            return {
                "summary": "I'm sorry, I couldn't analyze this product due to a technical issue.",
                "benefits": [],
                "considerations": [],
                "ideal_for": ""
            }
    
    async def compare_products_conversation(self, products: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Generate a conversational comparison of multiple investment products.
        """
        try:
            prompt = self._build_comparison_prompt(products)
            
            response = await self._generate_response(prompt)
        
            try:
                structured_response = self._parse_comparison_response(response)
                return structured_response
            except Exception as e:
                logger.warning(f"Failed to parse comparison response: {str(e)}")
                return {
                    "overview": response,
                    "key_differences": [],
                    "recommendation": "",
                    "considerations": []
                }
                
        except Exception as e:
            logger.error(f"Error comparing products: {str(e)}")
            return {
                "overview": "I'm sorry, I couldn't compare these products due to a technical issue.",
                "key_differences": [],
                "recommendation": "",
                "considerations": []
            }
            
    async def _fetch_user_context(self, user_id: str) -> Dict[str, Any]:
        """Fetch user context for personalized responses"""
        return {
            "risk_profile": "Moderate",
            "investment_goals": ["Retirement", "Growth"],
            "previous_investments": ["ETFs", "Stocks"],
            "age_group": "30-40",
            "time_horizon": "5-10 years"
        }
    
    async def _generate_response(self, prompt: str) -> str:
        """Generate response from the Gemini model"""
        try:
            response = await self.model.generate_content_async(prompt)
            return response.text
        except Exception as e:
            logger.error(f"Error generating AI response: {str(e)}")
            raise ValueError(f"Failed to generate response: {str(e)}")
    
    def _build_answer_prompt(self, query: UserQuery, user_context: Dict[str, Any]) -> str:
        """Build prompt for answering investment questions"""
        # products if available
        products_context = ""
        if query.products and len(query.products) > 0:
            products_json = json.dumps(query.products, indent=2)
            products_context = f"\nThe user is asking about these investment products:\n{products_json}\n"
        
        # user context if available
        user_info = ""
        if user_context:
            user_info = f"\nAdditional information about the user:\n{json.dumps(user_context, indent=2)}\n"
        
        # conversation history if available
        conversation_history = ""
        if query.conversation_history and len(query.conversation_history) > 0:
            try:
                history_items = []
                for msg in query.conversation_history[-3:]:  
                    if not isinstance(msg, dict):
                        logger.warning(f"Invalid conversation history item: {msg}")
                        continue
                        
                    user_msg = msg.get('user', '')
                    assistant_msg = msg.get('assistant', '')
                    
                    if user_msg:
                        history_items.append(f"User: {user_msg}")
                        if assistant_msg:
                            history_items.append(f"Assistant: {assistant_msg}")
                
                if history_items:
                    conversation_history = "\nRecent conversation history:\n" + "\n".join(history_items) + "\n"
            except Exception as e:
                logger.warning(f"Error processing conversation history: {str(e)}")
        
        return f"""
        You are a knowledgeable investment advisor assistant. Answer the user's question about investments
        in a helpful, accurate, and concise manner. Focus on being educational and informative rather than promotional.
        
        User question: {query.question}
        {products_context}
        {user_info}
        {conversation_history}
        
        Provide your response in a conversational, helpful tone. Include specific information when possible,
        and acknowledge limitations in your knowledge when appropriate. Avoid generic advice and tailor your 
        response to the specific question and context.
        
        Format your response as a JSON object with these fields:
        - answer: your main response to the question
        - follow_up_questions: an array of 2-3 natural follow-up questions the user might want to ask
        - resources: an array of types of resources the user might want to consult (e.g., "Financial advisor", "Tax professional", "Investment prospectus")
        """
    
    def _build_benefits_prompt(self, product: Dict[str, Any], user_context: Dict[str, Any]) -> str:
        """Build prompt for explaining product benefits"""
        product_json = json.dumps(product, indent=2)
        user_context_json = json.dumps(user_context, indent=2)
        
        return f"""
        You are a knowledgeable investment advisor assistant. Explain the benefits and considerations
        of this investment product to a potential investor:
        
        {product_json}
        
        User context:
        {user_context_json}
        
        Provide a balanced analysis that highlights both the potential benefits and important considerations.
        Be specific about who this investment might be most suitable for.
        
        Format your response as a JSON object with these fields:
        - summary: a brief overview of the product and its key benefits (2-3 sentences)
        - benefits: an array of specific benefits (4-6 items)
        - considerations: an array of important considerations or potential drawbacks (2-4 items)
        - ideal_for: a description of the ideal investor profile for this product
        """
    
    def _build_comparison_prompt(self, products: List[Dict[str, Any]]) -> str:
        """Build prompt for comparing multiple products in conversation"""
        products_json = json.dumps(products, indent=2)
        
        return f"""
        You are a knowledgeable investment advisor assistant. Compare these investment products
        for a potential investor:
        
        {products_json}
        
        Provide a balanced analysis that highlights the key differences between these products.
        Focus on helping the investor understand which product might be most suitable for different
        investment goals and risk profiles.
        
        Format your response as a JSON object with these fields:
        - overview: a conversational overview of the products being compared (3-4 sentences)
        - key_differences: an array of the most important differentiating factors between the products
        - recommendation: a nuanced recommendation that acknowledges different investor needs
        - considerations: an array of important factors the investor should keep in mind when deciding
        """
    
    def _parse_structured_response(self, response: str) -> Dict[str, Any]:
        """Parse structured response from Gemini"""
        try:
            json_start = response.find('{')
            json_end = response.rfind('}') + 1
            
            if json_start >= 0 and json_end > json_start:
                json_str = response[json_start:json_end]
                parsed_response = json.loads(json_str)
                
                if 'answer' in parsed_response:
                    return parsed_response
            
            return {
                "answer": response.strip(),
                "follow_up_questions": [],
                "resources": []
            }
            
        except Exception as e:
            logger.warning(f"Error parsing response as JSON: {str(e)}")
            return {
                "answer": response.strip(),
                "follow_up_questions": [],
                "resources": []
            }
    
    def _parse_benefits_response(self, response: str) -> Dict[str, Any]:
        """Parse structured benefits response from Gemini"""
        try:
            json_start = response.find('{')
            json_end = response.rfind('}') + 1
            
            if json_start >= 0 and json_end > json_start:
                json_str = response[json_start:json_end]
                parsed_response = json.loads(json_str)
                
                if 'summary' in parsed_response and 'benefits' in parsed_response:
                    return parsed_response
            
            return {
                "summary": response.strip(),
                "benefits": [],
                "considerations": [],
                "ideal_for": ""
            }
            
        except Exception as e:
            logger.warning(f"Error parsing benefits response as JSON: {str(e)}")
            return {
                "summary": response.strip(),
                "benefits": [],
                "considerations": [],
                "ideal_for": ""
            }
    
    def _parse_comparison_response(self, response: str) -> Dict[str, Any]:
        """Parse structured comparison response from Gemini"""
        try:
            json_start = response.find('{')
            json_end = response.rfind('}') + 1
            
            if json_start >= 0 and json_end > json_start:
                json_str = response[json_start:json_end]
                parsed_response = json.loads(json_str)
                
                if 'overview' in parsed_response and 'key_differences' in parsed_response:
                    return parsed_response
        
            return {
                "overview": response.strip(),
                "key_differences": [],
                "recommendation": "",
                "considerations": []
            }
            
        except Exception as e:
            logger.warning(f"Error parsing comparison response as JSON: {str(e)}")
            return {
                "overview": response.strip(),
                "key_differences": [],
                "recommendation": "",
                "considerations": []
            }