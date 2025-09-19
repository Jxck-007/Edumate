# backend/app.py - Modified for Rasa Integration

from flask import Flask, jsonify, request
from flask_cors import CORS
import requests
import json
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

class RasaService:
    def __init__(self):
        self.rasa_url = "http://localhost:5005"
        self.webhook_url = f"{self.rasa_url}/webhooks/rest/webhook"
    
    def send_message(self, message, sender_id="user"):
        """Send message to Rasa and get response"""
        try:
            payload = {
                'sender': sender_id,
                'message': message
            }
            
            logger.info(f"Sending to Rasa: {message}")
            
            response = requests.post(
                self.webhook_url,
                json=payload,
                timeout=10
            )
            
            if response.status_code == 200:
                rasa_responses = response.json()
                
                if rasa_responses and len(rasa_responses) > 0:
                    bot_response = rasa_responses[0].get('text', 'No response from AI')
                    logger.info(f"Rasa response: {bot_response}")
                    return {
                        'success': True,
                        'message': bot_response,
                        'source': 'rasa_ai'
                    }
                else:
                    return {
                        'success': False,
                        'message': 'No response from AI assistant',
                        'source': 'error'
                    }
            else:
                return {
                    'success': False,
                    'message': f'AI server error: {response.status_code}',
                    'source': 'error'
                }
                
        except requests.exceptions.ConnectionError:
            logger.error("Cannot connect to Rasa server")
            return {
                'success': False,
                'message': 'AI assistant is currently unavailable. Please ensure Rasa server is running on port 5005.',
                'source': 'connection_error'
            }
        except Exception as e:
            logger.error(f"Error communicating with Rasa: {str(e)}")
            return {
                'success': False,
                'message': 'Error communicating with AI assistant',
                'source': 'error'
            }
    
    def check_health(self):
        """Check if Rasa server is running"""
        try:
            response = requests.get(f"{self.rasa_url}/status", timeout=3)
            return response.status_code == 200
        except:
            return False

# Global Rasa service instance
rasa_service = RasaService()

@app.route('/api/health', methods=['GET'])
def health_check():
    """Check health of both backend and Rasa"""
    rasa_healthy = rasa_service.check_health()
    
    return jsonify({
        'status': 'healthy',
        'service': 'edumate_backend',
        'rasa_connected': rasa_healthy,
        'rasa_url': rasa_service.rasa_url,
        'timestamp': datetime.now().isoformat()
    }), 200

@app.route('/api/chat/message', methods=['POST'])
def chat_message():
    """Process chat message through Rasa AI"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        user_message = data.get('message', '').strip()
        session_id = data.get('session_id', 'default_user')
        
        if not user_message:
            return jsonify({'error': 'Message is required'}), 400
        
        logger.info(f"Processing message from {session_id}: {user_message}")
        
        # Send to Rasa AI
        rasa_result = rasa_service.send_message(user_message, session_id)
        
        if rasa_result['success']:
            return jsonify({
                'success': True,
                'message': rasa_result['message'],
                'session_id': session_id,
                'source': 'rasa_ai',
                'timestamp': datetime.now().isoformat()
            }), 200
        else:
            return jsonify({
                'success': False,
                'message': rasa_result['message'],
                'error': rasa_result.get('source', 'unknown'),
                'timestamp': datetime.now().isoformat()
            }), 503
            
    except Exception as e:
        logger.error(f"Error in chat endpoint: {str(e)}")
        return jsonify({
            'success': False,
            'message': 'Internal server error. Please try again.',
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/', methods=['GET'])
def root():
    """Root endpoint"""
    return jsonify({
        'service': 'Edumate Backend with Rasa Integration',
        'version': '2.0.0',
        'rasa_connected': rasa_service.check_health(),
        'endpoints': {
            'health': '/api/health',
            'chat': '/api/chat/message'
        }
    }), 200

if __name__ == '__main__':
    logger.info("🚀 Starting Edumate Backend with Rasa Integration...")
    logger.info("🤖 Checking Rasa connection...")
    
    if rasa_service.check_health():
        logger.info("✅ Rasa server is running and connected!")
    else:
        logger.warning("⚠️ Rasa server not found. Please start Rasa on port 5005")
        logger.info("💡 To start Rasa: rasa run --enable-api --cors '*' --port 5005")
    
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=True
    )