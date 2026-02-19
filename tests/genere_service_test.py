import pytest
from unittest.mock import MagicMock, patch

from services.genere_service import get_generes
from db.schemas.genere import Genere

@pytest.mark.asyncio
async def test_get_generes():
    # Mock the database session and query
    mock_genere_1 = MagicMock()
    mock_genere_1.id = 1
    mock_genere_1.name = "Rock"
    
    mock_genere_2 = MagicMock()
    mock_genere_2.id = 2
    mock_genere_2.name = "Pop"
    
    with patch('services.genere_service.get_db_sess') as mock_get_db:
        mock_db = MagicMock()
        mock_db.query().all.return_value = [mock_genere_1, mock_genere_2]
        mock_get_db.return_value.__enter__.return_value = mock_db
        
        generes = await get_generes()
        
        assert len(generes) == 2
        assert generes[0].id == 1
        assert generes[0].name == "Rock"
        assert generes[1].id == 2
        assert generes[1].name == "Pop"