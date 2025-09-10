import os
import logging
import asyncpg
import json
from datetime import datetime, timezone
from typing import List, Dict, Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database connection pool
db_pool = None

async def init_db_pool():
    """Initialize database connection pool"""
    global db_pool
    try:
        database_url = os.getenv("DATABASE_URL")
        if not database_url:
            logger.warning("DATABASE_URL not set - running without database")
            return None
            
        db_pool = await asyncpg.create_pool(
            database_url,
            min_size=1,
            max_size=10,
            command_timeout=60
        )
        logger.info("Database connection pool initialized")
        
        # Create tables if they don't exist
        await create_tables()
        return db_pool
        
    except Exception as e:
        logger.error(f"Failed to initialize database: {e}")
        return None

async def create_tables():
    """Create database tables if they don't exist"""
    if not db_pool:
        return
        
    async with db_pool.acquire() as conn:
        # Chat history table
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS chat_history (
                id SERIAL PRIMARY KEY,
                user_id VARCHAR(100) NOT NULL,
                message TEXT NOT NULL,
                response TEXT NOT NULL,
                confidence FLOAT NOT NULL DEFAULT 0.0,
                ai_powered BOOLEAN NOT NULL DEFAULT FALSE,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                session_id VARCHAR(100),
                metadata JSONB DEFAULT '{}'::jsonb
            );
        """)
        
        # Create indexes for better performance
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_chat_history_user_id 
            ON chat_history(user_id);
        """)
        
        await conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_chat_history_created_at 
            ON chat_history(created_at DESC);
        """)
        
        # User analytics table
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS user_analytics (
                id SERIAL PRIMARY KEY,
                user_id VARCHAR(100) NOT NULL,
                total_messages INTEGER DEFAULT 0,
                total_ai_messages INTEGER DEFAULT 0,
                avg_confidence FLOAT DEFAULT 0.0,
                first_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                UNIQUE(user_id)
            );
        """)
        
        logger.info("Database tables created/verified successfully")

async def close_db_pool():
    """Close database connection pool"""
    global db_pool
    if db_pool:
        await db_pool.close()
        logger.info("Database connection pool closed")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await init_db_pool()
    yield
    # Shutdown
    await close_db_pool()

# Initialize FastAPI with lifespan
app = FastAPI(
    title="RetailBot API",
    description="AI-powered retail assistant with persistent storage",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        # Azure Container Instance URLs will be added dynamically
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic models
class ChatMessage(BaseModel):
    message: str = Field(..., min_length=1, max_length=1000)
    user_id: str = Field(..., min_length=1, max_length=100)
    session_id: Optional[str] = None

class ChatResponse(BaseModel):
    response: str
    confidence: float
    timestamp: datetime
    ai_powered: bool = False
    session_id: Optional[str] = None

class HealthResponse(BaseModel):
    status: str
    service: str
    version: str
    timestamp: datetime
    database_connected: bool = False
    ai_enabled: bool = False

class ChatHistoryItem(BaseModel):
    id: int
    message: str
    response: str
    confidence: float
    ai_powered: bool
    created_at: datetime

class UserStats(BaseModel):
    total_messages: int
    total_ai_messages: int
    avg_confidence: float
    first_seen: datetime
    last_seen: datetime

# System prompt for AI
RETAIL_SYSTEM_PROMPT = """You are RetailBot, an expert retail and FMCG consultant. 
Provide specific, actionable advice with industry metrics. Keep responses concise but comprehensive.
Focus on practical solutions that drive business results."""

# Database helper functions
async def get_db_connection():
    """Get database connection from pool"""
    if not db_pool:
        return None
    return db_pool.acquire()

async def store_chat_message(user_id: str, message: str, response: str, 
                           confidence: float, ai_powered: bool, session_id: str = None):
    """Store chat message in database"""
    if not db_pool:
        logger.warning("Database not available - skipping storage")
        return
        
    try:
        async with db_pool.acquire() as conn:
            # Insert chat history
            await conn.execute("""
                INSERT INTO chat_history 
                (user_id, message, response, confidence, ai_powered, session_id, created_at)
                VALUES ($1, $2, $3, $4, $5, $6, $7)
            """, user_id, message, response, confidence, ai_powered, session_id, datetime.now(timezone.utc))
            
            # Update user analytics
            await conn.execute("""
                INSERT INTO user_analytics (user_id, total_messages, total_ai_messages, avg_confidence, first_seen, last_seen)
                VALUES ($1, 1, $2, $3, NOW(), NOW())
                ON CONFLICT (user_id) DO UPDATE SET
                    total_messages = user_analytics.total_messages + 1,
                    total_ai_messages = user_analytics.total_ai_messages + $2,
                    avg_confidence = (user_analytics.avg_confidence * user_analytics.total_messages + $3) / (user_analytics.total_messages + 1),
                    last_seen = NOW()
            """, user_id, 1 if ai_powered else 0, confidence)
            
            logger.info(f"Stored chat message for user {user_id}")
            
    except Exception as e:
        logger.error(f"Failed to store chat message: {e}")

async def get_user_chat_history(user_id: str, limit: int = 50) -> List[Dict]:
    """Get user's chat history from database"""
    if not db_pool:
        return []
        
    try:
        async with db_pool.acquire() as conn:
            rows = await conn.fetch("""
                SELECT id, message, response, confidence, ai_powered, created_at
                FROM chat_history 
                WHERE user_id = $1 
                ORDER BY created_at DESC 
                LIMIT $2
            """, user_id, limit)
            
            return [dict(row) for row in rows]
            
    except Exception as e:
        logger.error(f"Failed to get chat history: {e}")
        return []

async def get_user_stats(user_id: str) -> Optional[Dict]:
    """Get user statistics from database"""
    if not db_pool:
        return None
        
    try:
        async with db_pool.acquire() as conn:
            row = await conn.fetchrow("""
                SELECT total_messages, total_ai_messages, avg_confidence, first_seen, last_seen
                FROM user_analytics 
                WHERE user_id = $1
            """, user_id)
            
            return dict(row) if row else None
            
    except Exception as e:
        logger.error(f"Failed to get user stats: {e}")
        return None

# AI Integration
def check_openai_availability():
    """Check if OpenAI is available"""
    openai_key = os.getenv("OPENAI_API_KEY")
    return bool(openai_key and openai_key.startswith("sk-"))

async def generate_ai_response(user_message: str, user_id: str) -> tuple[str, float, bool]:
    """Generate AI response using OpenAI"""
    
    if not check_openai_availability():
        logger.info("OpenAI not available, using enhanced fallback")
        return get_enhanced_fallback_response(user_message), 0.75, False
    
    try:
        import openai
        client = openai.OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        
        # Get recent conversation history for context
        recent_history = await get_user_chat_history(user_id, limit=3)
        
        # Build conversation context
        messages = [{"role": "system", "content": RETAIL_SYSTEM_PROMPT}]
        
        # Add recent history for context
        for entry in reversed(recent_history):
            messages.append({"role": "user", "content": entry["message"]})
            messages.append({"role": "assistant", "content": entry["response"]})
        
        # Add current message
        messages.append({"role": "user", "content": user_message})
        
        # Call OpenAI API
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=messages,
            max_tokens=400,
            temperature=0.7,
            presence_penalty=0.1,
            frequency_penalty=0.1
        )
        
        ai_response = response.choices[0].message.content.strip()
        confidence = 0.88  # High confidence for AI responses
        
        logger.info(f"OpenAI response generated for user {user_id}")
        return ai_response, confidence, True
        
    except Exception as e:
        logger.error(f"OpenAI API error: {e}")
        return get_enhanced_fallback_response(user_message), 0.7, False

def get_enhanced_fallback_response(message: str) -> str:
    """Enhanced fallback responses for when AI is unavailable"""
    message_lower = message.lower()
    
    if "inventory" in message_lower:
        return "For FMCG inventory management: Implement ABC analysis (A-items need daily monitoring), maintain 15-20% safety stock, target 8-12x annual turnover. Use demand forecasting with seasonality adjustments and monitor stock-out rates (keep below 2%)."
    elif "customer" in message_lower:
        return "Customer experience optimization: Track NPS scores (target >50), implement personalization using purchase history, ensure omnichannel consistency. Focus on reducing customer effort scores. Omnichannel customers spend 15-35% more than single-channel customers."
    elif "sales" in message_lower:
        return "Sales optimization: Implement dynamic pricing (can boost revenue 2-5%), use cross-selling at checkout, optimize product placement. Track conversion rates, average basket size, and customer lifetime value. A/B test promotional strategies."
    elif "supply" in message_lower:
        return "Supply chain resilience: Diversify suppliers, maintain supplier scorecards tracking delivery and quality. Keep strategic safety stock for high-impact products. Target fill rates >98% and perfect order rates >95%."
    elif "analytics" in message_lower:
        return "Retail analytics dashboard: Include inventory turnover by category, gross margin trends, customer acquisition cost, lifetime value ratios, conversion rates by source, and stock-out frequencies. Use cohort analysis for retention insights."
    else:
        return "I specialize in retail and FMCG optimization. I can provide insights on inventory management, customer experience, sales optimization, supply chain, and analytics. What specific area interests you?"

# API Endpoints
@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    database_connected = db_pool is not None
    ai_enabled = check_openai_availability()
    
    return HealthResponse(
        status="healthy",
        service="retailbot-api",
        version="1.0.0",
        timestamp=datetime.now(timezone.utc),
        database_connected=database_connected,
        ai_enabled=ai_enabled
    )

@app.get("/ready")
async def readiness_check():
    """Readiness check for container orchestration"""
    return {"status": "ready", "timestamp": datetime.now(timezone.utc)}

@app.post("/api/chat", response_model=ChatResponse)
async def chat(message: ChatMessage):
    """Main chat endpoint with database persistence"""
    
    # Generate AI response
    response_text, confidence, ai_powered = await generate_ai_response(
        message.message, message.user_id
    )
    
    # Store in database
    await store_chat_message(
        message.user_id, 
        message.message, 
        response_text, 
        confidence, 
        ai_powered,
        message.session_id
    )
    
    return ChatResponse(
        response=response_text,
        confidence=confidence,
        timestamp=datetime.now(timezone.utc),
        ai_powered=ai_powered,
        session_id=message.session_id
    )

@app.get("/api/chat/history/{user_id}", response_model=List[ChatHistoryItem])
async def get_chat_history(user_id: str, limit: int = 50):
    """Get user's chat history"""
    history = await get_user_chat_history(user_id, limit)
    return [ChatHistoryItem(**item) for item in history]

@app.get("/api/user/{user_id}/stats", response_model=UserStats)
async def get_user_statistics(user_id: str):
    """Get user statistics"""
    stats = await get_user_stats(user_id)
    if not stats:
        raise HTTPException(status_code=404, detail="User not found")
    return UserStats(**stats)

@app.get("/api/metrics")
async def get_system_metrics():
    """Get system metrics for monitoring"""
    if not db_pool:
        return {"error": "Database not available"}
    
    try:
        async with db_pool.acquire() as conn:
            # Get overall statistics
            total_messages = await conn.fetchval("SELECT COUNT(*) FROM chat_history")
            total_users = await conn.fetchval("SELECT COUNT(DISTINCT user_id) FROM chat_history")
            ai_messages = await conn.fetchval("SELECT COUNT(*) FROM chat_history WHERE ai_powered = true")
            avg_confidence = await conn.fetchval("SELECT AVG(confidence) FROM chat_history WHERE ai_powered = true")
            
            return {
                "total_messages": total_messages,
                "total_users": total_users,
                "ai_messages": ai_messages,
                "ai_percentage": (ai_messages / total_messages * 100) if total_messages > 0 else 0,
                "avg_confidence": round(avg_confidence or 0, 2),
                "database_connected": True,
                "timestamp": datetime.now(timezone.utc)
            }
            
    except Exception as e:
        logger.error(f"Failed to get metrics: {e}")
        return {"error": "Failed to retrieve metrics"}

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "RetailBot API with Database Integration",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)# Backend update
# Backend update
