from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from .database import Base
from datetime import datetime

class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(String)
    due_date = Column(DateTime)
    status = Column(String)  # e.g., 'pending', 'completed'
    blocked_by_task_id = Column(Integer, ForeignKey('tasks.id'), nullable=True)

    blocked_by = relationship("Task", remote_side=[id])