# packages/core/enums.py
# Centralized enums for database field values following Python and SQLAlchemy best practices
# Single source of truth for all allowed values in the system

from enum import Enum

class ChannelType(str, Enum):
    """
    Communication channels where conversations can originate
    Used in: Conversation.channel
    
    Why str inheritance?
    - Ensures database stores "web", not "WEB" (the enum name)
    - Makes enum members behave like strings in Python
    - Compatible with JSON serialization without custom serializers
    
    Benefits of enum:
    - IDE autocomplete: ChannelType.WEB instead of typing "web"  
    - Typo prevention: can't accidentally write "telegarm"
    - Single place to add new channels
    - Easy to see all supported channels at a glance
    """
    WEB = "web"                    # Website chat widget
    TELEGRAM = "telegram"          # Telegram bot integration
    EMAIL = "email"                # Email-to-chat system
    WHATSAPP = "whatsapp"          # WhatsApp Business API
    MOBILE_APP = "mobile_app"      # Native mobile application

class ConversationType(str, Enum):
    """
    Business purpose of the conversation
    Used in: Conversation.conversation_type
    
    Determines:
    - Which AI model to use
    - Which team gets notified
    - What response templates to suggest
    - How to measure success metrics
    """
    SUPPORT = "support"            # Customer service help (Project A)
    SALES = "sales"                # Sales inquiry or demo request (Project B)
    GENERAL = "general"            # General questions, not classified
    FEEDBACK = "feedback"          # Customer feedback or suggestions
    BILLING = "billing"            # Payment, subscription, invoice questions
    TECHNICAL = "technical"        # Technical integration or API questions

class ConversationStatus(str, Enum):
    """
    Current state of the conversation
    Used in: Conversation.status
    
    Workflow:
    ACTIVE → CLOSED (normal completion)
    ACTIVE → ESCALATED → CLOSED (human intervention needed)
    ACTIVE → ARCHIVED (inactive for long time)
    """
    ACTIVE = "active"              # Ongoing conversation, expecting responses
    CLOSED = "closed"              # Resolved and completed  
    ESCALATED = "escalated"        # Transferred to human agent
    ARCHIVED = "archived"          # Inactive for 30+ days, moved to archive
    PENDING = "pending"            # Waiting for user response

class MessageType(str, Enum):
    """
    Who or what sent the message
    Used in: Message.message_type
    
    Determines:
    - How to display the message (left/right side, different colors)
    - Whether to track AI costs and metrics
    - Which conversation features to enable
    """
    USER = "user"                  # Human user typed this message
    ASSISTANT = "assistant"        # AI system generated this response
    SYSTEM = "system"              # Automated system message (login, transfer, etc.)
    HUMAN_AGENT = "human_agent"    # Human customer service agent response
    DEVELOPER = "developer"        # Debug message from developer
    TESTER = "tester"              # Test message from QA tester

class UserRole(str, Enum):
    """
    User permissions and access levels
    Used in: User.role
    
    Project A (Customer Support) roles:
    - USER: can chat, view their conversations
    - SUPPORT_AGENT: can view all conversations, respond as human
    - ADMIN: full system access, can manage users and settings
    
    Project B (Sales) roles:
    - SALES_REP: can manage their leads and opportunities
    - SALES_MANAGER: can view team performance, manage territories  
    - ADMIN: full system access
    
    Cross-project:
    - ADMIN: works for both projects with full access
    """
    # Customer/end-user roles
    USER = "user"                  # Standard user with basic access
    
    # Project A: Customer Support roles
    SUPPORT_AGENT = "support_agent"        # Can handle support conversations
    SUPPORT_MANAGER = "support_manager"    # Can manage support team and metrics
    
    # Project B: Sales roles  
    SALES_REP = "sales_rep"               # Individual sales representative
    SALES_MANAGER = "sales_manager"       # Sales team leader
    SALES_DIRECTOR = "sales_director"     # Regional or division sales leader
    
    # Cross-project administrative roles
    ADMIN = "admin"                # Full system administrator
    SUPER_ADMIN = "super_admin"    # Platform-wide administrator (our company)
    DEVELOPER = "developer"        # System developer with debug access
    TESTER = "tester"              # QA tester for system validation

class UserFeedback(str, Enum):
    """
    User rating of AI responses
    Used in: Message.user_feedback
    
    Simple thumbs up/down system for measuring AI response quality
    Used for:
    - AI model performance tracking
    - Identifying problematic responses for improvement
    - Business metrics on customer satisfaction
    """
    THUMBS_UP = "thumbs_up"        # User found the response helpful
    THUMBS_DOWN = "thumbs_down"    # User found the response unhelpful
    # NULL in database = no feedback provided (most common case)

# Utility functions for working with enums - following SQLAlchemy best practices

def get_enum_values(enum_class) -> list[str]:
    """
    Get all possible values for an enum as a list
    Useful for validation, API documentation, and UI dropdowns
    
    Example:
        get_enum_values(ChannelType) 
        # Returns: ['web', 'telegram', 'email', 'slack', ...]
    """
    return [item.value for item in enum_class]

def get_enum_choices(enum_class) -> list[tuple[str, str]]:
    """
    Get enum values as (value, label) tuples
    Useful for Django forms, admin interfaces, and API schemas
    
    Example:
        get_enum_choices(UserRole)
        # Returns: [('user', 'USER'), ('admin', 'ADMIN'), ...]
    """
    return [(item.value, item.name) for item in enum_class]

# Example usage in models (import these in models.py):
# from packages.core.enums import ChannelType, ConversationType, MessageType, UserRole
#
# class Conversation(Base):
#     # Simple string fields with enum defaults - this is our chosen approach
#     channel = Column(String(20), default=ChannelType.WEB, nullable=False)
#     conversation_type = Column(String(20), default=ConversationType.SUPPORT, nullable=False)
#
# # In application code:
# new_conversation = Conversation(
#     channel=ChannelType.TELEGRAM,  # IDE will autocomplete, stores "telegram"
#     conversation_type=ConversationType.SALES  # Stores "sales"
# )
#
# # Validation happens in FastAPI/Pydantic schemas, not at database level
# # This gives us flexibility while maintaining type safety in code