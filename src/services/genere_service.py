from db.repositories.genere_repository import get_db_sess
from db.models.genere import Genere as GenereModel
from db.schemas.genere import Genere

async def get_generes() -> list[Genere]:
    with get_db_sess() as db:
        generes_db = db.query(GenereModel).all()
        return [Genere(id=g.id, name=g.name) for g in generes_db]