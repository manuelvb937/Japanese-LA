import re

_PUNCTUATION = set('。、，．！？「」『』（）()[]{}【】・:;：；…,.!?')


def _katakana_to_hiragana(text: str) -> str:
    chars = []
    for char in text:
        code = ord(char)
        if 0x30A1 <= code <= 0x30F6:
            chars.append(chr(code - 0x60))
        else:
            chars.append(char)
    return ''.join(chars)


def _friendly_pos(pos: str) -> str:
    return {
        '名詞': 'noun',
        '動詞': 'verb',
        '形容詞': 'adjective',
        '副詞': 'adverb',
        '助詞': 'particle',
        '助動詞': 'auxiliary',
        '接続詞': 'conjunction',
        '感動詞': 'interjection',
        '接頭辞': 'prefix',
        '接尾辞': 'suffix',
        '記号': 'symbol',
    }.get(pos, pos or 'unknown')


class TokenizerService:
    def __init__(self) -> None:
        self._tokenizer = None
        self._mode = None
        try:
            from sudachipy import dictionary, tokenizer

            self._tokenizer = dictionary.Dictionary().create()
            self._mode = tokenizer.Tokenizer.SplitMode.A
        except Exception:
            self._tokenizer = None

    def tokenize(self, text: str) -> list[dict]:
        if self._tokenizer is None:
            return self._fallback_tokenize(text)

        tokens = []
        for m in self._tokenizer.tokenize(text, self._mode):
            surface = m.surface()
            if not surface.strip() or surface in _PUNCTUATION:
                continue
            pos = _friendly_pos(m.part_of_speech()[0])
            tokens.append(
                {
                    'surface': surface,
                    'lemma': m.dictionary_form(),
                    'reading': _katakana_to_hiragana(m.reading_form()),
                    'pos': pos,
                }
            )
        return tokens

    def _fallback_tokenize(self, text: str) -> list[dict]:
        parts = re.findall(r'[一-龯々〆ヵヶ]+|[ぁ-んァ-ヴー]+|[A-Za-z0-9]+', text)
        return [
            {
                'surface': part,
                'lemma': part,
                'reading': _katakana_to_hiragana(part),
                'pos': 'unknown',
            }
            for part in parts
            if part.strip()
        ]
