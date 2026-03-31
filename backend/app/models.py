from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from .database import Base


class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(String)
    due_date = Column(DateTime)
    status = Column(String)
    blocked_by_task_id = Column(Integer, ForeignKey("tasks.id", ondelete="SET NULL"), nullable=True)
