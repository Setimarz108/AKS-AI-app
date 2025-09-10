import React, { useState, useEffect, useRef } from 'react';
import axios from 'axios';
import './App.css';

function App() {
  const [messages, setMessages] = useState([
    { 
      type: 'bot', 
      text: 'Hello! I\'m RetailBot, your AI assistant for FMCG and retail optimization. How can I help you today?',
      timestamp: new Date()
    }
  ]);
  const [inputMessage, setInputMessage] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [apiStatus, setApiStatus] = useState({ 
    status: 'checking', 
    dbConnected: false, 
    aiEnabled: false 
  });
  const messagesEndRef = useRef(null);

  // Auto-scroll to bottom when new messages arrive
  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  // Check API health on component mount
  useEffect(() => {
    checkApiHealth();
  }, []);

  const checkApiHealth = async () => {
    try {
      // nginx proxies /health to backend:8000/health
      const response = await axios.get('/health');
      setApiStatus({
        status: 'connected',
        dbConnected: response.data.database_connected,
        aiEnabled: response.data.ai_enabled
      });
    } catch (error) {
      setApiStatus({ status: 'disconnected', dbConnected: false, aiEnabled: false });
      console.error('API health check failed:', error);
    }
  };

  const sendMessage = async (e) => {
    e.preventDefault();
    if (!inputMessage.trim()) return;

    const userMessage = {
      type: 'user',
      text: inputMessage,
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    setInputMessage('');
    setIsLoading(true);

    try {
      // nginx proxies /api/chat to backend:8000/api/chat
      const response = await axios.post('/api/chat', {
        message: inputMessage,
        user_id: `user_${Date.now()}`
      });

      const botMessage = {
        type: 'bot',
        text: response.data.response,
        confidence: response.data.confidence,
        ai_powered: response.data.ai_powered,
        timestamp: new Date(response.data.timestamp)
      };

      setMessages(prev => [...prev, botMessage]);
    } catch (error) {
      console.error('Error sending message:', error);
      const errorMessage = {
        type: 'bot',
        text: 'Sorry, I encountered an error processing your request. Please try again.',
        timestamp: new Date(),
        error: true
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  const formatTime = (timestamp) => {
    return new Date(timestamp).toLocaleTimeString([], { 
      hour: '2-digit', 
      minute: '2-digit' 
    });
  };

  const getStatusColor = () => {
    if (apiStatus.status === 'connected' && apiStatus.dbConnected) return '#10B981';
    if (apiStatus.status === 'connected') return '#F59E0B';
    return '#EF4444';
  };

  const getStatusText = () => {
    if (apiStatus.status === 'disconnected') return 'API Disconnected';
    if (!apiStatus.aiEnabled && !apiStatus.dbConnected) return 'Basic Mode (No AI/DB)';
    if (apiStatus.aiEnabled && !apiStatus.dbConnected) return 'AI Enabled (No DB)';
    if (!apiStatus.aiEnabled && apiStatus.dbConnected) return 'DB Connected (No AI)';
    return 'Fully Powered (AI + DB)';
  };

  return (
    <div className="app">
      <header className="app-header">
        <div className="header-content">
          <div className="title-section">
            <h1>RetailBot</h1>
            <p>AI-Powered FMCG & Retail Assistant</p>
          </div>
          <div className="status-indicator">
            <div 
              className="status-dot"
              style={{ backgroundColor: getStatusColor() }}
            ></div>
            <span className="status-text">{getStatusText()}</span>
          </div>
        </div>
      </header>

      <div className="chat-container">
        <div className="messages-container">
          {messages.map((message, index) => (
            <div key={index} className={`message ${message.type}`}>
              <div className="message-content">
                <div className="message-text">
                  {message.text}
                  {message.confidence && (
                    <div className="confidence">
                      Confidence: {(message.confidence * 100).toFixed(0)}%
                      {message.ai_powered && <span className="ai-badge">🤖 AI</span>}
                    </div>
                  )}
                </div>
                <div className="message-time">
                  {formatTime(message.timestamp)}
                </div>
              </div>
            </div>
          ))}
          
          {isLoading && (
            <div className="message bot">
              <div className="message-content">
                <div className="typing-indicator">
                  <span></span>
                  <span></span>
                  <span></span>
                </div>
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        <form className="input-form" onSubmit={sendMessage}>
          <div className="input-container">
            <input
              type="text"
              value={inputMessage}
              onChange={(e) => setInputMessage(e.target.value)}
              placeholder="Ask about inventory, sales, customer experience, or supply chain..."
              disabled={isLoading || apiStatus.status === 'disconnected'}
              className="message-input"
            />
            <button 
              type="submit" 
              disabled={!inputMessage.trim() || isLoading || apiStatus.status === 'disconnected'}
              className="send-button"
            >
              {isLoading ? '...' : 'Send'}
            </button>
          </div>
        </form>
      </div>

      <footer className="app-footer">
        <p>Demo environment - Built with React + FastAPI + Azure Container Instances</p>
      </footer>
    </div>
  );
}

export default App;/* Frontend change */
/* Full pipeline test Wed, Sep 10, 2025  4:30:21 PM */
/* Full pipeline test Wed, Sep 10, 2025  4:36:03 PM */
/* Full pipeline test Wed, Sep 10, 2025  4:45:11 PM */
