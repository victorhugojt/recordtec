import logging
from fastapi import APIRouter

router = APIRouter()
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@router.get("/health")
async def health():
    logger.info("Health check endpoint called")
    return {"message": "OK"}