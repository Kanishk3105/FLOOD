from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import update, delete
from . import models, schemas
import asyncio

async def get_tasks(db: AsyncSession, skip: int = 0, limit: int = 100, search: str = None, status: str = None):
    query = select(models.Task)
    if search:
        query = query.where(models.Task.title.contains(search))
    if status:
        query = query.where(models.Task.status == status)
    query = query.offset(skip).limit(limit)
    result = await db.execute(query)
    return result.scalars().all()

async def get_task(db: AsyncSession, task_id: int):
    query = select(models.Task).where(models.Task.id == task_id)
    result = await db.execute(query)
    return result.scalar_one_or_none()

async def create_task(db: AsyncSession, task: schemas.TaskCreate):
    db_task = models.Task(**task.dict())
    db.add(db_task)
    await db.commit()
    await db.refresh(db_task)
    # Simulate delay
    await asyncio.sleep(2)
    return db_task

async def update_task(db: AsyncSession, task_id: int, task: schemas.TaskUpdate):
    query = update(models.Task).where(models.Task.id == task_id).values(**task.dict())
    await db.execute(query)
    await db.commit()
    # Simulate delay
    await asyncio.sleep(2)
    return await get_task(db, task_id)

async def delete_task(db: AsyncSession, task_id: int):
    query = delete(models.Task).where(models.Task.id == task_id)
    await db.execute(query)
    await db.commit()
    return True