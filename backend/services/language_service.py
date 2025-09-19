from googletrans import Translator
import logging
from typing import Dict, Any

logger = logging.getLogger(__name__)

class LanguageService:
    def __init__(self):
        self.translator = Translator()
        self.supported_languages = ['en', 'hi', 'ta', 'te', 'ml', 'kn', 'bn']
    
    def detect_language(self, text: str) -> str:
        try:
            detection = self.translator.detect(text)
            return detection.lang if detection.lang in self.supported_languages else 'en'
        except:
            return 'en'
    
    def translate_for_rasa(self, text: str, source_lang: str) -> str:
        if source_lang == 'en':
            return text
        try:
            result = self.translator.translate(text, src=source_lang, dest='en')
            return result.text
        except:
            return text
    
    def translate_from_rasa(self, text: str, target_lang: str) -> str:
        if target_lang == 'en':
            return text
        try:
            result = self.translator.translate(text, src='en', dest=target_lang)
            return result.text
        except:
            return text

language_service = LanguageService()
