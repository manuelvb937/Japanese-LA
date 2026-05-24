from fastapi import FastAPI, File, Form, UploadFile
from dotenv import load_dotenv

from .models.schemas import OCRPage, OCRResponse, TokenResult
from .services.dictionary_service import DictionaryService
from .services.pdf_service import PDFService
from .services.tokenizer_service import TokenizerService
from .services.vision_service import VisionService

load_dotenv()
app = FastAPI(title='Japanese Reader PoC API')
vision_service = VisionService()
tokenizer_service = TokenizerService()
dictionary_service = DictionaryService()
pdf_service = PDFService()


@app.get('/health')
def health() -> dict:
    return {'status': 'ok'}


def _to_tokens(full_text: str) -> list[TokenResult]:
    raw_tokens = tokenizer_service.tokenize(full_text)
    out = []
    for t in raw_tokens:
        d = dictionary_service.lookup(t['surface'], t['lemma'])
        out.append(TokenResult(**t, meaning=d['meaning'], jlpt=d['jlpt']))
    return out


@app.post('/ocr/image', response_model=OCRResponse)
async def ocr_image(file: UploadFile = File(...), mode: str = Form('auto')) -> OCRResponse:
    image_bytes = await file.read()
    ocr_mode = 'TEXT_DETECTION' if mode == 'sign' else 'DOCUMENT_TEXT_DETECTION'
    data = vision_service.detect_text(image_bytes, ocr_mode)
    page = OCRPage(page_number=1, text=data['full_text'], words=data['words'])
    return OCRResponse(source_type='image', ocr_mode=ocr_mode, full_text=data['full_text'], pages=[page], tokens=_to_tokens(data['full_text']))


@app.post('/ocr/pdf', response_model=OCRResponse)
async def ocr_pdf(file: UploadFile = File(...), mode: str = Form('document'), max_pages: int = Form(3)) -> OCRResponse:
    pdf_bytes = await file.read()
    images = pdf_service.render_pages(pdf_bytes, max_pages=max_pages)
    pages = []
    texts = []
    for idx, img in enumerate(images, 1):
        data = vision_service.detect_text(img, 'DOCUMENT_TEXT_DETECTION')
        texts.append(data['full_text'])
        pages.append(OCRPage(page_number=idx, text=data['full_text'], words=data['words']))
    full_text = '\n'.join(texts)
    return OCRResponse(source_type='pdf', ocr_mode='DOCUMENT_TEXT_DETECTION', full_text=full_text, pages=pages, tokens=_to_tokens(full_text))
