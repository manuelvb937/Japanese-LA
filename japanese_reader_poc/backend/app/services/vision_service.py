import os

from google.cloud import vision


def _env_truthy(name: str) -> bool:
    return os.getenv(name, '').strip().lower() in {'1', 'true', 'yes', 'on'}


class VisionService:
    def __init__(self) -> None:
        self._client: vision.ImageAnnotatorClient | None = None

    @property
    def client(self) -> vision.ImageAnnotatorClient:
        if self._client is None:
            self._client = vision.ImageAnnotatorClient()
        return self._client

    def detect_text(self, image_bytes: bytes, mode: str) -> dict:
        if _env_truthy('MOCK_OCR'):
            mock_text = os.getenv('MOCK_OCR_TEXT') or '日本語を勉強します。'
            return {'full_text': mock_text, 'words': [], 'mock': True}

        image = vision.Image(content=image_bytes)
        context = vision.ImageContext(language_hints=['ja'])
        if mode == 'TEXT_DETECTION':
            response = self.client.text_detection(image=image, image_context=context)
        else:
            response = self.client.document_text_detection(image=image, image_context=context)
        if response.error.message:
            raise RuntimeError(response.error.message)

        annotation = response.full_text_annotation
        if annotation and annotation.text:
            full_text = annotation.text
        elif response.text_annotations:
            full_text = response.text_annotations[0].description
        else:
            full_text = ''

        words = []
        for page in annotation.pages if annotation else []:
            for block in page.blocks:
                for paragraph in block.paragraphs:
                    for word in paragraph.words:
                        text = ''.join(s.text for s in word.symbols)
                        bbox = [
                            {'x': getattr(v, 'x', 0), 'y': getattr(v, 'y', 0)}
                            for v in word.bounding_box.vertices
                        ]
                        words.append({'text': text, 'bounding_box': bbox})
        return {'full_text': full_text, 'words': words, 'mock': False}
