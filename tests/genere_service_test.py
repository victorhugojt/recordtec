from src.services.genere_service import get_generes

def test_get_generes():
    generes = get_generes()
    assert len(generes) == 2
    assert generes[0]["id"] == 1
    assert generes[0]["name"] == "Rock"
    assert generes[1]["id"] == 2
    assert generes[1]["name"] == "Pop"