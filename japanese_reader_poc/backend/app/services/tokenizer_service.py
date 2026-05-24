from sudachipy import dictionary, tokenizer


class TokenizerService:
    def __init__(self) -> None:
        self._tokenizer = dictionary.Dictionary().create()
        self._mode = tokenizer.Tokenizer.SplitMode.C

    def tokenize(self, text: str) -> list[dict]:
        tokens = []
        for m in self._tokenizer.tokenize(text, self._mode):
            surface = m.surface()
            if not surface.strip():
                continue
            pos = m.part_of_speech()[0]
            tokens.append(
                {
                    'surface': surface,
                    'lemma': m.dictionary_form(),
                    'reading': m.reading_form(),
                    'pos': pos,
                }
            )
        return tokens
