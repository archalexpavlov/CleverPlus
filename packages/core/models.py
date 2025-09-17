# packages/core/models.py
# Simplified Row Level Security models based on production best practices
# Following shared-table approach with minimal complexity

from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, DateTime, Text, Boolean, ForeignKey, Index
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship

# Import our centralized enums for consistent field values
from .enums import ChannelType, ConversationType, ConversationStatus, MessageType, UserRole, UserFeedback

# Base class for all database models
Base = declarative_base()

# Get current UTC timestamp for database records
def utc_now():
    return datetime.now(timezone.utc)

class Tenant(Base):
    """
    Root table for tenant isolation - each customer/organization
    Simple structure focused on essential fields only
    """
    __tablename__ = "tenants"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    slug = Column(String(50), unique=True, nullable=False, index=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=utc_now, nullable=False)
    
    users = relationship("User", back_populates="tenant", lazy="select")
    conversations = relationship("Conversation", back_populates="tenant", lazy="select")

    def __repr__(self) -> str:
        return f"<Tenant(id={self.id}, slug='{self.slug}')>"

class User(Base):
    """
    Users within tenants - simplified for both Project A (support) and B (sales)
    Essential fields only, no JSON metadata
    """
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(Integer, ForeignKey("tenants.id"), nullable=False, index=True)
    
    email = Column(String(255), nullable=False)
    username = Column(String(100), nullable=False)
    full_name = Column(String(255), nullable=True)
    hashed_password = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    
    # Role-based access control - what can this user do?
    # Using centralized enum ensures consistency and prevents typos
    # See packages/core/enums.py for all available roles and their descriptions
    role = Column(String(20), default=UserRole.USER, nullable=False)
    
    created_at = Column(DateTime, default=utc_now, nullable=False)
    last_login_at = Column(DateTime, nullable=True)
    
    tenant = relationship("Tenant", back_populates="users")
    conversations = relationship("Conversation", back_populates="user", lazy="select")
    messages = relationship("Message", back_populates="user", lazy="select")
    
    # ADDED: critical index for searching users by role in tenant
    __table_args__ = (
        Index('ix_users_tenant_email', 'tenant_id', 'email', unique=True),
        Index('ix_users_tenant_role', 'tenant_id', 'role'),
        Index('ix_users_tenant_created', 'tenant_id', 'created_at'),
    )

    def __repr__(self) -> str:
        return f"<User(id={self.id}, tenant_id={self.tenant_id}, role='{self.role}')>"

class Conversation(Base):
    """
    Chat conversations - minimal fields for both support and sales use cases
    No complex metadata - keep it simple and fast
    """
    __tablename__ = "conversations"
    
    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(Integer, ForeignKey("tenants.id"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    session_id = Column(String(255), nullable=False)
    title = Column(String(200), nullable=True)
    
    # Business context - what type of conversation is this?
    # Using enum ensures consistent categorization across the platform
    conversation_type = Column(String(15), default=ConversationType.SUPPORT, nullable=False)
    
    # Where did this conversation start?
    # See ChannelType enum for all supported communication channels
    channel = Column(String(15), default=ChannelType.WEB, nullable=False)
    
    # Conversation lifecycle management
    # See ConversationStatus enum for workflow details
    status = Column(String(10), default=ConversationStatus.ACTIVE, nullable=False)
    
    resolution_time_minutes = Column(Integer, nullable=True)
    satisfaction_score = Column(Integer, nullable=True)
    
    created_at = Column(DateTime, default=utc_now, nullable=False)
    updated_at = Column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)
    closed_at = Column(DateTime, nullable=True)
    
    tenant = relationship("Tenant", back_populates="conversations")
    user = relationship("User", back_populates="conversations")
    messages = relationship("Message", back_populates="conversation", 
                          order_by="Message.created_at", lazy="select")
    
    # Performance indexes for common business queries
    __table_args__ = (
        # "Show me all active conversations for tenant X"
        Index('ix_conversations_tenant_status', 'tenant_id', 'status'),
        
        # "Show me all conversations for specific user in tenant X"
        Index('ix_conversations_tenant_user', 'tenant_id', 'user_id'),
        
        # "Show me recent conversations for tenant X" (analytics dashboard)
        Index('ix_conversations_tenant_created', 'tenant_id', 'created_at'),
        
        # Analytics queries for business intelligence
        Index('ix_conversations_channel', 'channel'),
        Index('ix_conversations_type', 'conversation_type'),
    )

    def __repr__(self) -> str:
        return f"<Conversation(id={self.id}, tenant_id={self.tenant_id}, status='{self.status}')>"

class Message(Base):
    """
    Individual messages in conversations
    Simplified structure - no complex AI metadata that complicates queries
    """
    __tablename__ = "messages"
    
    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(Integer, ForeignKey("tenants.id"), nullable=False, index=True)
    conversation_id = Column(Integer, ForeignKey("conversations.id"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    content = Column(Text, nullable=False)
    
    # Who/what sent this message?
    # See MessageType enum for all possible message sources
    message_type = Column(String(15), default=MessageType.USER, nullable=False)
    
    # AI tracking fields - только для assistant сообщений
    ai_model = Column(String(50), nullable=True)
    tokens_used = Column(Integer, nullable=True)
    
    # User feedback on AI responses - did this answer help?
    # Simple thumbs up/down system for AI improvement
    # See UserFeedback enum for possible values
    # NULL = no feedback given (most common)
    user_feedback = Column(String(15), nullable=True)
    
    created_at = Column(DateTime, default=utc_now, nullable=False)
    
    tenant = relationship("Tenant")
    conversation = relationship("Conversation", back_populates="messages")
    user = relationship("User", back_populates="messages")
    
    # Essential indexes for common query patterns
    __table_args__ = (
        # "Show me all messages in conversation X for tenant Y"
        # Most common query - loading a conversation for display
        Index('ix_messages_tenant_conversation', 'tenant_id', 'conversation_id'),
        
        # "Show messages in conversation X in chronological order"
        # For displaying conversation history in correct order  
        Index('ix_messages_conversation_created', 'conversation_id', 'created_at'),
        
        # Performance indexes for analytics and filtering
        Index('ix_messages_tenant_user', 'tenant_id', 'user_id'),
        Index('ix_messages_type', 'message_type'),
        Index('ix_messages_ai_model', 'ai_model'),
    )

    def __repr__(self) -> str:
        return f"<Message(id={self.id}, tenant_id={self.tenant_id}, type='{self.message_type}')>"

# Row Level Security Policies will be added via SQL migrations
# Each table will get automatic filtering: WHERE tenant_id = current_setting('app.current_tenant')::integer