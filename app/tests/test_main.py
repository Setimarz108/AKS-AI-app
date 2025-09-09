import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert "status" in data
    assert data["status"] == "healthy"

def test_chat_endpoint():
    response = client.post("/api/chat", json={
        "message": "test message",
        "user_id": "test_user"
    })
    assert response.status_code == 200
    data = response.json()
    assert "response" in data
    assert "confidence" in data

def test_docs_endpoint():
    response = client.get("/docs")
    assert response.status_code == 200