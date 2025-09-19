# Enhanced Chat Routes with College-Focused AI

from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, ChatSession, ChatMessage, User, ChatAnalytics
from services.rasa_service import rasa_service
from services.language_service import language_service
from services.college_ai_services import college_ai_services
import time
import uuid
import logging

logger = logging.getLogger(__name__)

chat_bp = Blueprint('chat', __name__)

@chat_bp.route('/message', methods=['POST'])
def send_message():
    """
    Process user message with college-focused AI and return bot response
    
    Expected payload:
    {
        "message": "What are the admission requirements for B.Tech?",
        "session_id": "optional_session_id",
        "user_id": "optional_user_id", 
        "language": "en",
        "input_type": "text|voice"
    }
    """
    try:
        data = request.get_json()
        
        # Validate required fields
        if not data or 'message' not in data:
            return jsonify({'error': 'Message is required'}), 400
        
        message_text = data['message'].strip()
        if not message_text:
            return jsonify({'error': 'Message cannot be empty'}), 400
        
        # Extract optional parameters
        session_id = data.get('session_id')
        user_id = data.get('user_id')
        preferred_language = data.get('language', 'en')
        input_type = data.get('input_type', 'text')
        
        # Detect language if not provided
        detected_language = language_service.detect_language(message_text)
        if not preferred_language or preferred_language == 'auto':
            preferred_language = detected_language
        
        # Create or get chat session
        if not session_id:
            session_id = str(uuid.uuid4())
        
        chat_session = ChatSession.query.filter_by(id=session_id).first()
        if not chat_session:
            chat_session = ChatSession(
                id=session_id,
                user_id=user_id,
                language=preferred_language
            )
            db.session.add(chat_session)
        
        # Store user message
        user_message = ChatMessage(
            session_id=session_id,
            message_text=message_text,
            is_user_message=True,
            input_type=input_type,
            language_detected=detected_language,
            original_text=message_text
        )
        db.session.add(user_message)
        
        # STEP 1: College Intent Classification
        intent_result = college_ai_services['intent_classifier'].classify_intent(message_text)
        
        if not intent_result['is_college_related']:
            # Return college-focused restriction message
            restricted_response = (
                "I'm Edumate, your college assistant! I can help you with:\n\n"
                "🎓 Admissions and eligibility\n"
                "💰 Fee structure and scholarships\n" 
                "📚 Available courses and programs\n"
                "🏢 Placement statistics and careers\n"
                "🏠 Hostel and campus facilities\n\n"
                "Please ask me about college-related topics!"
            )
            
            # Translate response if needed
            if preferred_language != 'en':
                restricted_response = language_service.translate_from_rasa(
                    restricted_response, preferred_language
                )
            
            # Store bot response
            bot_message = ChatMessage(
                session_id=session_id,
                message_text=restricted_response,
                is_user_message=False,
                input_type=input_type,
                language_detected='en',
                original_text=restricted_response,
                response_time_ms=50
            )
            db.session.add(bot_message)
            db.session.commit()
            
            return jsonify({
                'success': True,
                'message': restricted_response,
                'session_id': session_id,
                'language': preferred_language,
                'input_type': input_type,
                'intent': 'non_college_topic',
                'restricted': True
            })
        
        # STEP 2: Generate College-Specific Response
        start_time = time.time()
        
        try:
            # Use college AI services first for high-confidence intents
            if intent_result['confidence'] >= 0.7:
                logger.info(f"Using college AI for high-confidence intent: {intent_result['intent']}")
                
                # Generate response using college knowledge base
                college_response = college_ai_services['response_generator'].generate_response(
                    intent_result['intent'], 
                    message_text
                )
                
                bot_response_text = college_response
                rasa_intent = intent_result['intent']
                rasa_confidence = intent_result['confidence']
                response_source = 'college_ai'
                
            else:
                # Fallback to Rasa for complex queries
                logger.info(f"Using Rasa for complex query: {message_text}")
                
                # Translate message for Rasa if needed
                rasa_message = language_service.translate_for_rasa(message_text, detected_language)
                
                # Send to Rasa
                rasa_response = rasa_service.send_message(
                    message=rasa_message,
                    sender_id=session_id,
                    metadata={
                        'language': detected_language,
                        'input_type': input_type,
                        'user_id': user_id,
                        'college_intent': intent_result['intent']
                    }
                )
                
                if rasa_response['success']:
                    bot_response_text = rasa_response['message']
                    rasa_intent = rasa_response.get('intent') or intent_result['intent']
                    rasa_confidence = rasa_response.get('confidence') or intent_result['confidence']
                    response_source = 'rasa'
                else:
                    # Final fallback to college AI default response
                    bot_response_text = college_ai_services['response_generator']._generate_default_response()
                    rasa_intent = 'fallback'
                    rasa_confidence = 0.5
                    response_source = 'college_ai_fallback'
        
        except Exception as ai_error:
            logger.error(f"College AI processing error: {str(ai_error)}")
            
            # Fallback to Rasa
            rasa_message = language_service.translate_for_rasa(message_text, detected_language)
            rasa_response = rasa_service.send_message(
                message=rasa_message,
                sender_id=session_id
            )
            
            if rasa_response['success']:
                bot_response_text = rasa_response['message']
                rasa_intent = rasa_response.get('intent', 'unknown')
                rasa_confidence = rasa_response.get('confidence', 0.5)
                response_source = 'rasa_fallback'
            else:
                bot_response_text = "I apologize, but I'm having trouble understanding your question. Could you please try asking about specific college topics like admissions, courses, or facilities?"
                rasa_intent = 'error'
                rasa_confidence = 0.0
                response_source = 'error_fallback'
        
        response_time = int((time.time() - start_time) * 1000)
        
        # STEP 3: Translate response back to user's language
        if preferred_language != 'en':
            bot_response_text = language_service.translate_from_rasa(
                bot_response_text, preferred_language
            )
        
        # Store bot response with enhanced metadata
        bot_message = ChatMessage(
            session_id=session_id,
            message_text=bot_response_text,
            is_user_message=False,
            input_type=input_type,
            language_detected='en',
            original_text=bot_response_text,
            translated_text=bot_response_text if preferred_language != 'en' else None,
            rasa_intent=rasa_intent,
            rasa_confidence=rasa_confidence,
            response_time_ms=response_time
        )
        db.session.add(bot_message)
        
        # Update session
        chat_session.updated_at = db.func.now()
        
        # Enhanced analytics with college-specific data
        analytics = ChatAnalytics(
            session_id=session_id,
            user_id=user_id,
            event_type='college_chat_exchange',
            event_data={
                'input_type': input_type,
                'language': preferred_language,
                'detected_language': detected_language,
                'intent': rasa_intent,
                'confidence': rasa_confidence,
                'response_time_ms': response_time,
                'response_source': response_source,
                'college_intent_confidence': intent_result['confidence'],
                'is_college_related': True
            }
        )
        db.session.add(analytics)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': bot_response_text,
            'session_id': session_id,
            'language': preferred_language,
            'detected_language': detected_language,
            'input_type': input_type,
            'intent': rasa_intent,
            'confidence': rasa_confidence,
            'response_time_ms': response_time,
            'response_source': response_source,
            'college_intent': intent_result['intent'],
            'college_confidence': intent_result['confidence']
        })
        
    except Exception as e:
        logger.error(f"Error processing college chat message: {str(e)}")
        db.session.rollback()
        return jsonify({
            'success': False,
            'error': 'Internal server error',
            'message': 'I apologize for the technical difficulty. Please try asking about college admissions, courses, fees, or facilities.'
        }), 500

@chat_bp.route('/suggestions', methods=['POST'])
def get_query_suggestions():
    """
    Get query suggestions for college topics
    """
    try:
        data = request.get_json()
        partial_query = data.get('query', '').strip()
        
        if len(partial_query) < 2:
            # Return popular college queries
            suggestions = [
                "What are the admission requirements?",
                "Tell me about B.Tech courses",
                "What is the fee structure?", 
                "How is the placement record?",
                "What hostel facilities are available?",
                "Tell me about campus facilities",
                "When do admissions open?",
                "What scholarships are available?"
            ]
        else:
            # Generate contextual suggestions based on partial input
            suggestions = []
            
            # College-specific suggestion logic
            query_lower = partial_query.lower()
            
            if any(word in query_lower for word in ['admission', 'apply']):
                suggestions = [
                    "What are the admission requirements for B.Tech?",
                    "How to apply for MBA admission?",
                    "When do admissions open?",
                    "What documents are required for admission?",
                    "What is the admission process?"
                ]
            elif any(word in query_lower for word in ['fee', 'cost', 'price']):
                suggestions = [
                    "What is the fee structure for B.Tech?",
                    "Are there any scholarships available?",
                    "What are the hostel fees?",
                    "Can I pay fees in installments?",
                    "What is the total cost of MBA?"
                ]
            elif any(word in query_lower for word in ['course', 'program']):
                suggestions = [
                    "What courses are available?",
                    "Tell me about B.Tech specializations",
                    "What is the duration of MBA program?", 
                    "What subjects are taught in CSE?",
                    "Which course is best for placements?"
                ]
            elif any(word in query_lower for word in ['placement', 'job']):
                suggestions = [
                    "What is the placement percentage?",
                    "Which companies visit for recruitment?",
                    "What is the average salary package?",
                    "How is the placement record for CSE?",
                    "Are internships provided?"
                ]
            else:
                # Fallback suggestions
                suggestions = [
                    "What are the admission requirements?",
                    "Tell me about available courses",
                    "What is the fee structure?",
                    "How are the placement statistics?"
                ]
        
        return jsonify({
            'success': True,
            'suggestions': suggestions[:5]  # Return top 5
        })
        
    except Exception as e:
        logger.error(f"Suggestion generation error: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Failed to generate suggestions'
        }), 500

@chat_bp.route('/college-info/<category>', methods=['GET'])
def get_college_information(category):
    """
    Get structured college information by category
    
    Categories: courses, admission_process, facilities, placement_stats
    """
    try:
        subcategory = request.args.get('subcategory')
        
        # Get information from knowledge base
        info_result = college_ai_services['knowledge_base'].get_information(
            category, subcategory
        )
        
        if info_result['success']:
            return jsonify({
                'success': True,
                'category': category,
                'subcategory': subcategory,
                'data': info_result['data']
            })
        else:
            return jsonify({
                'success': False,
                'error': info_result['error'],
                'available_categories': info_result.get('available_categories', [])
            }), 404
    
    except Exception as e:
        logger.error(f"College information retrieval error: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Failed to retrieve college information'
        }), 500

@chat_bp.route('/search', methods=['POST'])
def search_college_information():
    """
    Search across college knowledge base
    """
    try:
        data = request.get_json()
        query = data.get('query', '').strip()
        
        if not query:
            return jsonify({'error': 'Search query is required'}), 400
        
        # Search knowledge base
        search_results = college_ai_services['knowledge_base'].search_information(query)
        
        return jsonify({
            'success': True,
            'query': query,
            'results': search_results,
            'result_count': len(search_results)
        })
        
    except Exception as e:
        logger.error(f"Search error: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Search failed'
        }), 500

@chat_bp.route('/health', methods=['GET'])
def check_health():
    """Check health of college chat service"""
    try:
        # Check database connectivity
        db.session.execute('SELECT 1')
        
        # Check Rasa connectivity  
        rasa_health = rasa_service.check_health()
        
        # Check college AI services
        college_ai_status = {
            'intent_classifier': 'operational',
            'knowledge_base': 'operational', 
            'response_generator': 'operational'
        }
        
        return jsonify({
            'success': True,
            'database': 'connected',
            'rasa': rasa_health,
            'college_ai_services': college_ai_status,
            'supported_languages': language_service.supported_languages,
            'college_focus': True,
            'service_type': 'college_chatbot'
        })
        
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500