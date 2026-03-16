from fastapi import APIRouter
from services.genere_service import get_generes
from typing import List
from db.schemas.genere import Genere
import logging

router = APIRouter()
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@router.get("/generes")
async def get_generes_controller() -> List[Genere]:
    logger.info("Generes endpoint called")
    generes = await get_generes()
    logger.info(f"Generes: {generes}")
    return generes