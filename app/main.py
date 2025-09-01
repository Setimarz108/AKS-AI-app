import os
import logging
from datetime import datetime
from typing import List, Dict

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="RetailBot API",
    description="AI-powered retail assistant for FMCG sector",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic models
class ChatMessage(BaseModel):
    message: str = Field(..., min_length=1, max_length=1000)
    user_id: str = Field(..., min_length=1, max_length=100)

class ChatResponse(BaseModel):
    response: str
    confidence: float
    timestamp: datetime
    ai_powered: bool = False

class HealthResponse(BaseModel):
    status: str
    service: str
    version: str
    timestamp: datetime
    ai_enabled: bool = False

# System prompt for retail expertise
RETAIL_SYSTEM_PROMPT = """You are RetailBot, an expert AI consultant specializing in retail and FMCG (Fast-Moving Consumer Goods) industries. You have deep knowledge in:

- Inventory management and supply chain optimization
- Customer experience and journey mapping  
- Sales strategies and revenue optimization
- Market analysis and consumer behavior
- Digital transformation in retail
- Omnichannel strategies
- Data analytics and KPI tracking
- Operational efficiency improvements

Provide specific, actionable advice based on industry best practices. Include relevant metrics, percentages, or benchmarks when possible. Keep responses professional, concise (2-3 paragraphs max), and focused on practical implementation."""

# Mock storage
mock_chat_history = []

def get_openai_client():
    """Get OpenAI client safely"""
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        return None
    
    try:
        import openai
        return openai.OpenAI(api_key=api_key)
    except Exception as e:
        logger.error(f"Failed to initialize OpenAI client: {e}")
        return None

async def generate_ai_response(user_message: str, user_id: str) -> tuple[str, float, bool]:
    """Generate AI response using OpenAI"""
    
    client = get_openai_client()
    if not client:
        return get_fallback_response(user_message), 0.75, False
    
    try:
        # Get conversation history
        recent_history = get_conversation_history(user_id, limit=4)
        
        # Build messages
        messages = [{"role": "system", "content": RETAIL_SYSTEM_PROMPT}]
        
        # Add history
        for entry in recent_history:
            messages.append({"role": "user", "content": entry["message"]})
            messages.append({"role": "assistant", "content": entry["response"]})
        
        # Add current message
        messages.append({"role": "user", "content": user_message})
        
        # Call OpenAI
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=messages,
            max_tokens=400,
            temperature=0.7
        )
        
        ai_response = response.choices[0].message.content
        confidence = calculate_confidence(ai_response, user_message)
        
        logger.info(f"OpenAI response generated for user {user_id}")
        return ai_response, confidence, True
        
    except Exception as e:
        logger.error(f"OpenAI API error: {e}")
        return get_fallback_response(user_message), 0.7, False

def calculate_confidence(response: str, user_message: str) -> float:
    """Calculate confidence score"""
    base_confidence = 0.85
    
    if len(response) > 200:
        base_confidence += 0.05
    
    retail_keywords = ["inventory", "sales", "customer", "supply", "retail"]
    if any(keyword in user_message.lower() for keyword in retail_keywords):
        base_confidence += 0.05
    
    if any(indicator in response.lower() for indicator in ["%", "should", "recommend"]):
        base_confidence += 0.05
        
    return min(0.95, max(0.75, base_confidence))

def get_fallback_response(message: str) -> str:
    """Fallback responses when OpenAI unavailable"""
    message_lower = message.lower()
    
    responses = {
        "customer": "Customer experience optimization requires tracking NPS scores (target >50), implementing personalization using purchase history, and ensuring omnichannel consistency. Focus on reducing customer effort scores and real-time feedback loops. Omnichannel customers typically spend 15-35% more than single-channel customers.",
        
        "inventory": "For FMCG inventory management: Use ABC analysis (A-items need daily monitoring), maintain 15-20% safety stock, target 8-12x annual turnover for most categories. Implement demand forecasting with seasonality and keep stock-out rates below 2%. Monitor inventory-to-sales ratios monthly.",
        
        "sales": "Sales optimization: Implement dynamic pricing (2-5% revenue boost), use cross-selling at checkout, optimize placement with heat mapping. Track conversion rates, basket size, customer lifetime value. A/B test promotions and use personalized recommendations.",
        
        "supply": "Supply chain resilience: Diversify suppliers, use scorecards for performance tracking, maintain strategic safety stock. Target >98% fill rates and >95% perfect order rates. Implement supply chain mapping to identify bottlenecks.",
        
        "analytics": "Key retail KPIs: inventory turnover by category, gross margins, customer acquisition cost, conversion rates by channel, stock-out frequencies. Use automated alerts and cohort analysis for retention insights."
    }
    
    for keyword, response in responses.items():
        if keyword in message_lower:
            return response
    
    return "I specialize in retail and FMCG optimization. I can help with inventory management, customer experience, sales strategies, supply chain, and analytics. What would you like to explore?"

def get_conversation_history(user_id: str, limit: int = 4) -> List[Dict]:
    """Get recent conversation history"""
    user_messages = [entry for entry in mock_chat_history if entry["user_id"] == user_id]
    return user_messages[-limit:] if user_messages else []

def store_chat_message(user_id: str, message: str, response: str, confidence: float, ai_powered: bool):
    """Store chat message"""
    chat_entry = {
        "user_id": user_id,
        "message": message,
        "response": response,
        "confidence": confidence,
        "ai_powered": ai_powered,
        "timestamp": datetime.utcnow()
    }
    mock_chat_history.append(chat_entry)
    
    # Keep last 100 messages
    if len(mock_chat_history) > 100:
        mock_chat_history.pop(0)

# API Endpoints
@app.get("/health", response_model=HealthResponse)
async def health_check():
    return HealthResponse(
        status="healthy",
        service="retailbot-api",
        version="1.0.0",
        timestamp=datetime.utcnow(),
        ai_enabled=bool(os.getenv("OPENAI_API_KEY"))
    )

@app.post("/api/chat", response_model=ChatResponse)
async def chat(message: ChatMessage):
    """Chat endpoint with LLM integration"""
    
    # Generate response
    response_text, confidence, ai_powered = await generate_ai_response(message.message, message.user_id)
    
    # Store interaction
    store_chat_message(message.user_id, message.message, response_text, confidence, ai_powered)
    
    logger.info(f"Chat response for user {message.user_id} (AI: {ai_powered})")
    
    return ChatResponse(
        response=response_text,
        confidence=confidence,
        timestamp=datetime.utcnow(),
        ai_powered=ai_powered
    )

@app.get("/")
async def root():
    return {
        "message": "RetailBot API with LLM integration!",
        "ai_enabled": bool(os.getenv("OPENAI_API_KEY"))
    }