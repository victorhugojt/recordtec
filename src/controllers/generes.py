from fastapi import APIRouter
from services.genere_service import get_generes
from typing import List
from db.schemas.genere import Genere

router = APIRouter()

@router.get("/generes")
async def get_generes_controller() -> List[Genere]:
    return await get_generes()