# College-Focused AI Services for Edumate Chatbot

import numpy as np
import pandas as pd
from typing import Dict, List, Any, Optional, Tuple
from textblob import TextBlob
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import joblib
import logging
import re
from datetime import datetime, timedelta
import json

logger = logging.getLogger(__name__)

class CollegeIntentClassifier:
    """Advanced college-specific intent classification"""
    
    def __init__(self):
        self.college_intents = {
            'admission_inquiry': {
                'keywords': ['admission', 'apply', 'entrance', 'eligibility', 'requirements', 'form', 'application'],
                'patterns': [r'how to (apply|get admission)', r'admission (process|procedure)', r'entrance exam'],
                'weight': 3
            },
            'fee_inquiry': {
                'keywords': ['fee', 'cost', 'price', 'payment', 'scholarship', 'installment', 'tuition'],
                'patterns': [r'how much (does it cost|fees)', r'fee structure', r'total cost'],
                'weight': 3
            },
            'course_information': {
                'keywords': ['course', 'program', 'degree', 'subjects', 'curriculum', 'syllabus', 'duration'],
                'patterns': [r'what courses', r'available programs', r'course details'],
                'weight': 3
            },
            'placement_inquiry': {
                'keywords': ['placement', 'job', 'career', 'salary', 'companies', 'recruitment', 'internship'],
                'patterns': [r'placement (record|statistics)', r'job opportunities', r'career prospects'],
                'weight': 3
            },
            'hostel_accommodation': {
                'keywords': ['hostel', 'accommodation', 'room', 'mess', 'residence', 'boarding'],
                'patterns': [r'hostel (facilities|booking)', r'accommodation available', r'room allocation'],
                'weight': 2
            },
            'faculty_information': {
                'keywords': ['faculty', 'professor', 'teacher', 'staff', 'instructor', 'qualification'],
                'patterns': [r'faculty (details|information)', r'about professors', r'teaching staff'],
                'weight': 2
            },
            'campus_facilities': {
                'keywords': ['library', 'lab', 'sports', 'canteen', 'wifi', 'transport', 'medical'],
                'patterns': [r'campus facilities', r'library timings', r'sports complex'],
                'weight': 2
            },
            'academic_schedule': {
                'keywords': ['timetable', 'schedule', 'exam', 'result', 'calendar', 'semester'],
                'patterns': [r'class (schedule|timetable)', r'exam (dates|schedule)', r'academic calendar'],
                'weight': 2
            }
        }
    
    def classify_intent(self, text: str) -> Dict[str, Any]:
        """
        Classify user input into college-specific intents
        
        Args:
            text: User input text
            
        Returns:
            Dictionary with intent classification results
        """
        try:
            text_lower = text.lower()
            intent_scores = {}
            
            # Score each intent based on keywords and patterns
            for intent_name, intent_data in self.college_intents.items():
                score = 0
                
                # Keyword matching
                for keyword in intent_data['keywords']:
                    if keyword in text_lower:
                        score += intent_data['weight']
                
                # Pattern matching
                for pattern in intent_data['patterns']:
                    if re.search(pattern, text_lower):
                        score += intent_data['weight'] * 1.5  # Patterns get higher weight
                
                intent_scores[intent_name] = score
            
            # Find the highest scoring intent
            if intent_scores:
                top_intent = max(intent_scores.items(), key=lambda x: x[1])
                confidence = min(top_intent[1] / 10, 1.0)  # Normalize confidence
                
                if confidence >= 0.3:  # Minimum confidence threshold
                    return {
                        'intent': top_intent[0],
                        'confidence': confidence,
                        'all_scores': intent_scores,
                        'is_college_related': True
                    }
            
            # Check if it's college-related but unclear intent
            college_keywords = ['college', 'university', 'student', 'education', 'academic']
            if any(keyword in text_lower for keyword in college_keywords):
                return {
                    'intent': 'general_college_inquiry',
                    'confidence': 0.5,
                    'all_scores': intent_scores,
                    'is_college_related': True
                }
            
            return {
                'intent': 'unknown',
                'confidence': 0.0,
                'all_scores': intent_scores,
                'is_college_related': False
            }
            
        except Exception as e:
            logger.error(f"Intent classification error: {str(e)}")
            return {
                'intent': 'error',
                'confidence': 0.0,
                'error': str(e),
                'is_college_related': False
            }

class CollegeKnowledgeBase:
    """Dynamic knowledge base for college information"""
    
    def __init__(self):
        self.knowledge_base = {
            'courses': {
                'btech': {
                    'full_name': 'Bachelor of Technology',
                    'duration': '4 years',
                    'specializations': ['Computer Science', 'Electronics', 'Mechanical', 'Civil', 'Electrical'],
                    'eligibility': '12th with PCM, minimum 75%',
                    'fee_range': '1.5-2.5 lakh per year',
                    'career_options': ['Software Engineer', 'Data Scientist', 'System Administrator']
                },
                'mtech': {
                    'full_name': 'Master of Technology',
                    'duration': '2 years',
                    'specializations': ['AI/ML', 'VLSI', 'Power Systems', 'Structural Engineering'],
                    'eligibility': 'BE/BTech with 60% minimum',
                    'fee_range': '2-3 lakh per year',
                    'career_options': ['Research Scientist', 'Technical Lead', 'Product Manager']
                },
                'mba': {
                    'full_name': 'Master of Business Administration',
                    'duration': '2 years',
                    'specializations': ['Marketing', 'Finance', 'HR', 'Operations', 'Strategy'],
                    'eligibility': 'Any graduate with 50% + CAT/MAT',
                    'fee_range': '3-5 lakh per year',
                    'career_options': ['Manager', 'Consultant', 'Business Analyst', 'Entrepreneur']
                }
            },
            'admission_process': {
                'application_period': 'May 1 - June 30',
                'entrance_exam': 'JEE Main/Advanced for BTech, GATE for MTech, CAT/MAT for MBA',
                'selection_criteria': 'Entrance exam score + 12th marks + Interview',
                'documents_required': [
                    '10th and 12th mark sheets',
                    'Transfer certificate',
                    'Character certificate',
                    'Caste certificate (if applicable)',
                    'Income certificate',
                    'Passport size photos'
                ]
            },
            'facilities': {
                'library': {
                    'books': '50,000+ books and journals',
                    'digital': 'Access to IEEE, ACM, Springer databases',
                    'timings': '8:00 AM - 10:00 PM (Mon-Sat), 9:00 AM - 6:00 PM (Sun)',
                    'features': ['Silent reading zones', 'Group discussion rooms', 'Computer terminals']
                },
                'hostel': {
                    'capacity': '2000 students',
                    'room_types': ['Single', 'Double', 'Triple occupancy'],
                    'facilities': ['Wi-Fi', 'Mess', 'Recreation room', 'Gym', 'Medical room'],
                    'fees': 'Rs. 4,500-8,000 per month',
                    'mess_charges': 'Rs. 3,500 per month'
                },
                'labs': {
                    'computer_labs': '5 labs with 200+ computers',
                    'specialized_labs': ['VLSI Lab', 'Robotics Lab', 'IoT Lab', 'AI/ML Lab'],
                    'equipment': 'Latest software and hardware',
                    'access_hours': '9:00 AM - 8:00 PM'
                }
            },
            'placement_stats': {
                'overall_percentage': 95,
                'average_package': '8.5 LPA',
                'highest_package': '45 LPA',
                'top_recruiters': [
                    'Microsoft', 'Google', 'Amazon', 'TCS', 'Infosys',
                    'Wipro', 'Accenture', 'IBM', 'Flipkart', 'Paytm'
                ],
                'placement_process': [
                    'Pre-placement talks (September)',
                    'Resume preparation workshops',
                    'Mock interviews',
                    'Campus drives (November-March)',
                    'Final placements'
                ]
            }
        }
    
    def get_information(self, category: str, subcategory: str = None) -> Dict[str, Any]:
        """
        Retrieve information from knowledge base
        
        Args:
            category: Main category (courses, admission_process, etc.)
            subcategory: Specific subcategory if needed
            
        Returns:
            Dictionary with requested information
        """
        try:
            if category in self.knowledge_base:
                if subcategory and subcategory in self.knowledge_base[category]:
                    return {
                        'success': True,
                        'data': self.knowledge_base[category][subcategory],
                        'category': category,
                        'subcategory': subcategory
                    }
                else:
                    return {
                        'success': True,
                        'data': self.knowledge_base[category],
                        'category': category
                    }
            else:
                return {
                    'success': False,
                    'error': f'Category {category} not found',
                    'available_categories': list(self.knowledge_base.keys())
                }
                
        except Exception as e:
            logger.error(f"Knowledge base retrieval error: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def search_information(self, query: str) -> List[Dict[str, Any]]:
        """
        Search across knowledge base for relevant information
        
        Args:
            query: Search query
            
        Returns:
            List of matching information pieces
        """
        try:
            query_lower = query.lower()
            results = []
            
            # Search through all categories
            for category, category_data in self.knowledge_base.items():
                if isinstance(category_data, dict):
                    for subcategory, subcategory_data in category_data.items():
                        # Convert to searchable text
                        searchable_text = json.dumps(subcategory_data).lower()
                        
                        # Simple keyword matching
                        query_words = query_lower.split()
                        matches = sum(1 for word in query_words if word in searchable_text)
                        
                        if matches > 0:
                            relevance_score = matches / len(query_words)
                            results.append({
                                'category': category,
                                'subcategory': subcategory,
                                'data': subcategory_data,
                                'relevance_score': relevance_score
                            })
            
            # Sort by relevance
            results.sort(key=lambda x: x['relevance_score'], reverse=True)
            return results[:5]  # Return top 5 matches
            
        except Exception as e:
            logger.error(f"Knowledge base search error: {str(e)}")
            return []

class CollegeResponseGenerator:
    """Generate contextual responses for college queries"""
    
    def __init__(self, knowledge_base: CollegeKnowledgeBase):
        self.knowledge_base = knowledge_base
        self.response_templates = {
            'admission_inquiry': """
🎓 **Admission Information:**

**Application Period:** {application_period}
**Entrance Exam:** {entrance_exam}
**Selection Process:** {selection_criteria}

**Required Documents:**
{documents}

**Next Steps:**
1. Fill online application form
2. Pay application fee
3. Take entrance exam
4. Attend counseling (if selected)

📞 **Contact:** admissions@college.edu | 0123-456-7890
            """,
            'course_information': """
📚 **{course_name} Details:**

**Duration:** {duration}
**Specializations Available:**
{specializations}

**Eligibility:** {eligibility}
**Fee Range:** {fee_range}

**Career Opportunities:**
{career_options}

**Would you like more details about any specific specialization?**
            """,
            'fee_inquiry': """
💰 **Fee Structure for {course}:**

**Annual Fees:** {fee_range}
**Additional Costs:**
• Hostel: Rs. 4,500-8,000/month
• Mess: Rs. 3,500/month
• Books & Materials: Rs. 10,000/year

**Payment Options:**
• Annual payment (5% discount)
• Semester-wise payment
• EMI facility available

**Scholarships Available:**
• Merit-based scholarships up to 50%
• Need-based financial assistance
• Government scholarships for eligible categories
            """,
            'placement_inquiry': """
📈 **Placement Statistics:**

**Placement Rate:** {overall_percentage}%
**Average Package:** Rs. {average_package}
**Highest Package:** Rs. {highest_package}

**Top Recruiters:**
{top_recruiters}

**Placement Process:**
{placement_process}

**Industry Connections:**
• Regular industry visits
• Guest lectures by professionals  
• Internship opportunities
• Skill development workshops
            """
        }
    
    def generate_response(self, intent: str, query: str, context: Dict = None) -> str:
        """
        Generate contextual response based on intent and query
        
        Args:
            intent: Classified intent
            query: Original user query
            context: Additional context information
            
        Returns:
            Formatted response string
        """
        try:
            if intent == 'admission_inquiry':
                return self._generate_admission_response()
            
            elif intent == 'course_information':
                course = self._extract_course_from_query(query)
                return self._generate_course_response(course)
            
            elif intent == 'fee_inquiry':
                course = self._extract_course_from_query(query)
                return self._generate_fee_response(course)
            
            elif intent == 'placement_inquiry':
                return self._generate_placement_response()
            
            elif intent == 'hostel_accommodation':
                return self._generate_hostel_response()
            
            elif intent == 'campus_facilities':
                return self._generate_facilities_response()
            
            else:
                # Fallback with search results
                search_results = self.knowledge_base.search_information(query)
                if search_results:
                    return self._generate_search_based_response(search_results, query)
                else:
                    return self._generate_default_response()
        
        except Exception as e:
            logger.error(f"Response generation error: {str(e)}")
            return "I apologize, but I'm having trouble processing your request right now. Please try asking about specific topics like admissions, courses, fees, or placements."
    
    def _extract_course_from_query(self, query: str) -> str:
        """Extract course name from query"""
        query_lower = query.lower()
        
        if any(term in query_lower for term in ['btech', 'b.tech', 'bachelor', 'engineering']):
            return 'btech'
        elif any(term in query_lower for term in ['mtech', 'm.tech', 'master', 'technology']):
            return 'mtech'
        elif any(term in query_lower for term in ['mba', 'management', 'business']):
            return 'mba'
        else:
            return 'btech'  # Default
    
    def _generate_admission_response(self) -> str:
        """Generate admission-related response"""
        admission_info = self.knowledge_base.get_information('admission_process')
        
        if admission_info['success']:
            data = admission_info['data']
            documents_list = '\n'.join(f"• {doc}" for doc in data['documents_required'])
            
            return self.response_templates['admission_inquiry'].format(
                application_period=data['application_period'],
                entrance_exam=data['entrance_exam'],
                selection_criteria=data['selection_criteria'],
                documents=documents_list
            )
        
        return "Please contact our admissions office for detailed admission information."
    
    def _generate_course_response(self, course: str) -> str:
        """Generate course-specific response"""
        course_info = self.knowledge_base.get_information('courses', course)
        
        if course_info['success']:
            data = course_info['data']
            specializations_list = '\n'.join(f"• {spec}" for spec in data['specializations'])
            career_list = '\n'.join(f"• {career}" for career in data['career_options'])
            
            return self.response_templates['course_information'].format(
                course_name=data['full_name'],
                duration=data['duration'],
                specializations=specializations_list,
                eligibility=data['eligibility'],
                fee_range=data['fee_range'],
                career_options=career_list
            )
        
        return f"I don't have detailed information about {course}. Please contact our academic office for specific course details."
    
    def _generate_fee_response(self, course: str) -> str:
        """Generate fee-related response"""
        course_info = self.knowledge_base.get_information('courses', course)
        
        if course_info['success']:
            data = course_info['data']
            
            return self.response_templates['fee_inquiry'].format(
                course=data['full_name'],
                fee_range=data['fee_range']
            )
        
        return "Please contact our accounts office for detailed fee information."
    
    def _generate_placement_response(self) -> str:
        """Generate placement statistics response"""
        placement_info = self.knowledge_base.get_information('placement_stats')
        
        if placement_info['success']:
            data = placement_info['data']
            recruiters_list = '\n'.join(f"• {company}" for company in data['top_recruiters'][:5])
            process_list = '\n'.join(f"• {step}" for step in data['placement_process'])
            
            return self.response_templates['placement_inquiry'].format(
                overall_percentage=data['overall_percentage'],
                average_package=data['average_package'],
                highest_package=data['highest_package'],
                top_recruiters=recruiters_list,
                placement_process=process_list
            )
        
        return "Please contact our placement cell for current placement statistics."
    
    def _generate_hostel_response(self) -> str:
        """Generate hostel information response"""
        hostel_info = self.knowledge_base.get_information('facilities', 'hostel')
        
        if hostel_info['success']:
            data = hostel_info['data']
            facilities_list = '\n'.join(f"• {facility}" for facility in data['facilities'])
            
            return f"""
🏠 **Hostel Accommodation:**

**Capacity:** {data['capacity']}
**Room Types:** {', '.join(data['room_types'])}

**Facilities:**
{facilities_list}

**Fees:**
• Accommodation: {data['fees']}
• Mess charges: {data['mess_charges']}

**Booking Process:**
1. Complete admission formalities
2. Submit hostel application
3. Pay hostel fees and security deposit
4. Get room allocation

📞 **Contact Hostel Office:** hostel@college.edu
            """
        
        return "Please contact the hostel office for accommodation details."
    
    def _generate_facilities_response(self) -> str:
        """Generate campus facilities response"""
        facilities_info = self.knowledge_base.get_information('facilities')
        
        if facilities_info['success']:
            data = facilities_info['data']
            
            return f"""
🏫 **Campus Facilities:**

**📚 Library:**
• {data['library']['books']}
• Digital access: {data['library']['digital']}
• Timings: {data['library']['timings']}

**💻 Computer Labs:**
• {data['labs']['computer_labs']}
• Specialized labs: {', '.join(data['labs']['specialized_labs'])}
• Access: {data['labs']['access_hours']}

**🏠 Hostel:**
• Capacity: {data['hostel']['capacity']}
• Types: {', '.join(data['hostel']['room_types'])}

**Additional Facilities:**
• Sports complex with gym
• Medical center
• Cafeteria and mess
• Transportation
• Wi-Fi campus
            """
        
        return "Please visit our campus to see all the facilities we offer."
    
    def _generate_search_based_response(self, search_results: List[Dict], query: str) -> str:
        """Generate response based on search results"""
        response = f"Here's what I found related to '{query}':\n\n"
        
        for i, result in enumerate(search_results[:3], 1):
            response += f"**{i}. {result['category'].title()}:**\n"
            
            # Format the data nicely
            data = result['data']
            if isinstance(data, dict):
                for key, value in data.items():
                    if isinstance(value, list):
                        value = ', '.join(str(v) for v in value[:3])
                    response += f"• {key.replace('_', ' ').title()}: {value}\n"
            
            response += "\n"
        
        response += "Would you like more specific information about any of these topics?"
        return response
    
    def _generate_default_response(self) -> str:
        """Generate default fallback response"""
        return """
🎓 **I'm here to help with college information!**

**Popular topics I can assist with:**
• 📝 Admissions and eligibility criteria
• 💰 Fee structure and scholarships
• 📚 Available courses and specializations
• 🏢 Placement statistics and career prospects
• 🏠 Hostel accommodation and facilities
• 🏫 Campus facilities and infrastructure
• 📅 Academic calendar and schedules

**Try asking me:**
• "What are the admission requirements for B.Tech?"
• "Tell me about MBA fees and scholarships"
• "How is the placement record?"
• "What hostel facilities are available?"

**Need immediate help?** Contact our office:
📞 Phone: 0123-456-7890
📧 Email: info@college.edu
        """

# Initialize college-specific AI services
college_ai_services = {
    'intent_classifier': CollegeIntentClassifier(),
    'knowledge_base': CollegeKnowledgeBase(),
    'response_generator': None  # Will be initialized after knowledge_base
}

# Initialize response generator with knowledge base
college_ai_services['response_generator'] = CollegeResponseGenerator(
    college_ai_services['knowledge_base']
)