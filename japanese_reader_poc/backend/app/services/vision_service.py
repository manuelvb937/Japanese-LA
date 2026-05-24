from google.cloud import vision


class VisionService:
    def __init__(self) -> None:
        self._client = vision.ImageAnnotatorClient()

    def detect_text(self, image_bytes: bytes, mode: str) -> dict:
        image = vision.Image(content=image_bytes)
        context = vision.ImageContext(language_hints=['ja'])
        if mode == 'TEXT_DETECTION':
            response = self._client.text_detection(image=image, image_context=context)
        else:
            response = self._client.document_text_detection(image=image, image_context=context)
        if response.error.message:
            raise RuntimeError(response.error.message)

        annotation = response.full_text_annotation
        full_text = annotation.text if annotation else ''
        words = []
        for page in annotation.pages if annotation else []:
            for block in page.blocks:
                for paragraph in block.paragraphs:
                    for word in paragraph.words:
                        text = ''.join(s.text for s in word.symbols)
                        bbox = [{'x': v.x, 'y': v.y} for v in word.bounding_box.vertices]
                        words.append({'text': text, 'bounding_box': bbox})
        return {'full_text': full_text, 'words': words}
