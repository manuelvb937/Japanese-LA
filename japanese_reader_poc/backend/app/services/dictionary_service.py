import json
from pathlib import Path


class DictionaryService:
    def __init__(self) -> None:
        data_dir = Path(__file__).resolve().parent.parent / 'data'
        jmdict_path = data_dir / 'dictionary_jmdict.json'
        mock_path = data_dir / 'dictionary_mock.json'
        jlpt_path = data_dir / 'jlpt_mock.json'
        self._source = 'dictionary_jmdict.json' if jmdict_path.exists() else 'dictionary_mock.json'
        path = jmdict_path if jmdict_path.exists() else mock_path
        self._entries = self._normalize_entries(json.loads(path.read_text(encoding='utf-8')))
        self._jlpt = self._normalize_jlpt(json.loads(jlpt_path.read_text(encoding='utf-8'))) if jlpt_path.exists() else {}

    def lookup(self, surface: str, lemma: str) -> dict:
        for key in self._candidate_keys(surface, lemma):
            entry = self._entries.get(key)
            if entry:
                return {
                    'meaning': entry['meaning'],
                    'jlpt': self._jlpt.get(key, entry.get('jlpt', 'unknown')),
                }

        for key in self._candidate_keys(surface, lemma):
            jlpt = self._jlpt.get(key)
            if jlpt:
                return {
                    'meaning': 'Dictionary entry not found yet',
                    'jlpt': jlpt,
                }

        return {
            'meaning': 'Dictionary entry not found yet',
            'jlpt': 'unknown',
        }

    @property
    def source(self) -> str:
        return f'{self._source}+jlpt_mock.json' if self._jlpt else self._source

    def _normalize_entries(self, raw_entries: dict) -> dict:
        entries = {}
        for key, value in raw_entries.items():
            if isinstance(value, str):
                entries[key] = {'meaning': value, 'jlpt': 'unknown'}
                continue

            meanings = value.get('meanings') if isinstance(value, dict) else None
            meaning = value.get('meaning') if isinstance(value, dict) else None
            if not meaning and isinstance(meanings, list):
                meaning = '; '.join(str(item) for item in meanings[:4])

            entries[key] = {
                'meaning': meaning or 'Dictionary entry not found yet',
                'jlpt': value.get('jlpt', 'unknown') if isinstance(value, dict) else 'unknown',
            }
        return entries

    def _normalize_jlpt(self, raw_entries: dict) -> dict[str, str]:
        normalized = {}
        for level, words in raw_entries.items():
            if not isinstance(words, list):
                continue
            for word in words:
                if isinstance(word, str) and word:
                    normalized[word] = level
        return normalized

    def _candidate_keys(self, surface: str, lemma: str) -> list[str]:
        keys = []
        for key in (surface, lemma):
            if key and key not in keys:
                keys.append(key)
            if key.startswith(('お', 'ご')) and len(key) > 1:
                polite_stripped = key[1:]
                if polite_stripped not in keys:
                    keys.append(polite_stripped)
        return keys
