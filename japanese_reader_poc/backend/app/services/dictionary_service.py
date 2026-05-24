import json
from pathlib import Path


class DictionaryService:
    def __init__(self) -> None:
        path = Path(__file__).resolve().parent.parent / 'data' / 'dictionary_mock.json'
        self._entries = json.loads(path.read_text(encoding='utf-8'))

    def lookup(self, surface: str, lemma: str) -> dict:
        return self._entries.get(surface) or self._entries.get(lemma) or {
            'meaning': 'Dictionary entry not found yet',
            'jlpt': 'unknown',
        }
