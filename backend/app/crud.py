import asyncio
from typing import Optional

from sqlalchemy import delete, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from . import models, schemas


async def get_tasks(
    db: AsyncSession,
    skip: int = 0,
    limit: int = 100,
    search: Optional[str] = None,
    status: Optional[str] = None,
):
    query = select(models.Task).order_by(models.Task.id)
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
    payload = task.model_dump()
    db_task = models.Task(**payload)
    db.add(db_task)
    await db.commit()
    await db.refresh(db_task)
    await asyncio.sleep(2)
    return db_task


async def update_task(db: AsyncSession, task_id: int, task: schemas.TaskUpdate):
    payload = task.model_dump()
    stmt = update(models.Task).where(models.Task.id == task_id).values(**payload)
    result = await db.execute(stmt)
    await db.commit()
    if result.rowcount == 0:
        return None
    await asyncio.sleep(2)
    return await get_task(db, task_id)


async def delete_task(db: AsyncSession, task_id: int):
    await db.execute(
        update(models.Task)
        .where(models.Task.blocked_by_task_id == task_id)
        .values(blocked_by_task_id=None)
    )
    stmt = delete(models.Task).where(models.Task.id == task_id)
    result = await db.execute(stmt)
    await db.commit()
    return result.rowcount > 0
