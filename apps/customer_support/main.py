from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Create FastAPI app
app = FastAPI(
    title="Clever+ - AI Agent Platform - Customer Support",
    description="Customer support AI agent with escalation capabilities",
    version="0.1.0"
)

# Setup CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, limit to specific domains
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    """Main API page"""
    return {
        "message": "AI Agent Platform - Customer Support API",
        "version": "0.1.0",
        "docs": "/docs",
        "health": "/health"
    }

@app.get("/health")
async def health_check():
    """Check server status"""
    return {
        "status": "healthy",
        "service": "customer-support",
        "version": "0.1.0"
    }

@app.get("/api/v1/chat")
async def chat_endpoint():
    """Base endpoint for chat (empty)"""
    return {
        "message": "Chat endpoint - coming soon",
        "status": "not_implemented"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)