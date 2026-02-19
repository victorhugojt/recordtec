from sqlalchemy import Column, Integer, String
from db.repositories.genere_repository import Base

class Genere(Base):
    """SQLAlchemy model for genere table."""
    
    __tablename__ = "generes"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), nullable=False)
    
    def to_dict(self):
        """Convert model to dictionary."""
        return {
            "id": self.id,
            "name": self.name
        }
