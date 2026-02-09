from fastapi import APIRouter
from services.genere_service import get_generes
from typing import List, Dict, Any

router = APIRouter()

@router.get("/generes")
async def get_generes_controller() -> List[Dict[str, Any]]:
    return get_generes()