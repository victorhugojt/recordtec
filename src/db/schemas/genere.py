from pydantic import BaseModel

class Genere(BaseModel):
    id: int
    name: str