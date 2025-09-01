import os
import logging
from datetime import datetime
from typing import Optional

from fastapi import FastAPI, HTTPException
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

# CORS middleware - important for React frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:3000"],  # React dev server
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

class HealthResponse(BaseModel):
    status: str
    service: str
    version: str
    timestamp: datetime
    database_connected: bool = False

# Mock database for testing
mock_chat_history = []

# Health check endpoint
@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint for testing"""
    return HealthResponse(
        status="healthy",
        service="retailbot-api",
        version="1.0.0",
        timestamp=datetime.utcnow(),
        database_connected=False  # Set to False for testing without DB
    )

@app.get("/ready")
async def readiness_check():
    """Readiness check"""
    return {"status": "ready", "timestamp": datetime.utcnow()}

# Chat endpoint with mock data storage
@app.post("/api/chat", response_model=ChatResponse)
async def chat(message: ChatMessage):
    """Main chat endpoint with intelligent response selection"""
    # Enhanced mock responses
    mock_responses = {
        "inventory": "In the FMCG sector, optimal inventory management involves maintaining 85-95% fill rates while minimizing holding costs. Consider implementing just-in-time delivery and demand forecasting.",
        "optimize": "For retail optimization, focus on: 1) Customer journey mapping, 2) Data-driven pricing strategies, 3) Supply chain efficiency, and 4) Omnichannel integration.",
        "sales": "To boost sales performance, implement dynamic pricing, personalized recommendations, and loyalty programs. Track conversion rates and customer lifetime value.",
        "supply": "Supply chain resilience requires diversified suppliers, real-time visibility, and risk assessment. Consider nearshoring and sustainability metrics.",
        "customer": "Customer experience optimization involves personalization, seamless omnichannel interactions, and proactive support. Use NPS and CSAT metrics to measure success.",
        "analytics": "Use real-time analytics to track KPIs like inventory turnover, customer acquisition cost, and profit margins. Implement automated alerts for threshold breaches.",
        "hello": "Hello! I'm RetailBot, your AI assistant for FMCG and retail optimization. I can help with inventory management, sales strategies, customer experience, and supply chain optimization.",
        "default": "I'm here to help with retail and FMCG insights! Ask me about inventory management, sales optimization, customer experience, or supply chain strategies."
    }
    
    # Intelligent response selection
    message_lower = message.message.lower()
    response_key = "default"
    
    for key in mock_responses.keys():
        if key in message_lower:
            response_key = key
            break
    
    response_text = mock_responses[response_key]
    confidence = 0.85 if response_key != "default" else 0.70
    
    # Store in mock database for testing
    chat_entry = {
        "user_id": message.user_id,
        "message": message.message,
        "response": response_text,
        "confidence": confidence,
        "timestamp": datetime.utcnow()
    }
    mock_chat_history.append(chat_entry)
    
    # Log the interaction
    logger.info(f"Chat request from user {message.user_id}: {message.message[:50]}...")
    
    return ChatResponse(
        response=response_text,
        confidence=confidence,
        timestamp=datetime.utcnow()
    )

@app.get("/api/recent-chats")
async def get_recent_chat_history(limit: int = 10):
    """Get recent chat interactions from mock database"""
    recent_chats = mock_chat_history[-limit:] if mock_chat_history else []
    return {
        "chats": recent_chats,
        "total_count": len(recent_chats),
        "timestamp": datetime.utcnow()
    }

@app.get("/api/metrics")
async def get_metrics():
    """Metrics endpoint"""
    return {
        "service": "retailbot-api",
        "version": "1.0.0",
        "uptime": "healthy",
        "database_status": "mock_mode",
        "total_chats": len(mock_chat_history),
        "timestamp": datetime.utcnow()
    }

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "RetailBot API is running!",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health",
        "metrics": "/api/metrics"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)