import requests
import logging
from typing import Dict, Any

logger = logging.getLogger(__name__)

class RasaService:
    def __init__(self, rasa_url: str = "http://localhost:5005"):
        self.rasa_url = rasa_url
        self.webhook_endpoint = f"{self.rasa_url}/webhooks/rest/webhook"
    
    def send_message(self, message: str, sender_id: str, metadata: Dict = None) -> Dict[str, Any]:
        try:
            payload = {
                'sender': sender_id,
                'message': message
            }
            if metadata:
                payload['metadata'] = metadata
            
            response = requests.post(
                self.webhook_endpoint,
                json=payload,
                timeout=10
            )
            
            if response.status_code == 200:
                rasa_response = response.json()
                if rasa_response:
                    return {
                        'success': True,
                        'message': rasa_response[0].get('text', 'No response'),
                        'intent': rasa_response[0].get('intent', {}).get('name'),
                        'confidence': rasa_response[0].get('intent', {}).get('confidence')
                    }
            
            return {'success': False, 'error': f'HTTP {response.status_code}'}
            
        except Exception as e:
            logger.error(f"Rasa service error: {str(e)}")
            return {'success': False, 'error': str(e)}
    
    def check_health(self) -> Dict[str, str]:
        try:
            response = requests.get(f"{self.rasa_url}/status", timeout=5)
            return {'status': 'healthy' if response.status_code == 200 else 'unhealthy'}
        except:
            return {'status': 'unreachable'}

rasa_service = RasaService()
