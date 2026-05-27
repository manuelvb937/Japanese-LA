import os

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

from .models.schemas import OCRPage, OCRResponse, TokenResult
from .services.dictionary_service import DictionaryService
from .services.pdf_service import PDFService
from .services.tokenizer_service import TokenizerService
from .services.vision_service import VisionService

load_dotenv()
app = FastAPI(title='Japanese Reader PoC API')
app.add_middleware(
    CORSMiddleware,
    allow_origins=['*'],
    allow_credentials=False,
    allow_methods=['*'],
    allow_headers=['*'],
)
vision_service = VisionService()
tokenizer_service = TokenizerService()
dictionary_service = DictionaryService()
pdf_service = PDFService()


@app.get('/health')
def health() -> dict:
    return {
        'status': 'ok',
        'dictionary': dictionary_service.source,
        'mock_ocr': bool(os.getenv('MOCK_OCR_TEXT')),
    }


def _to_tokens(full_text: str) -> list[TokenResult]:
    raw_tokens = tokenizer_service.tokenize(full_text)
    out = []
    for t in raw_tokens:
        d = dictionary_service.lookup(t['surface'], t['lemma'])
        out.append(TokenResult(**t, meaning=d['meaning'], jlpt=d['jlpt']))
    return out


def _image_ocr_mode(mode: str) -> str:
    normalized = mode.lower()
    if normalized == 'sign':
        return 'TEXT_DETECTION'
    if normalized in {'auto', 'book', 'document'}:
        return 'DOCUMENT_TEXT_DETECTION'
    raise HTTPException(status_code=400, detail='mode must be sign, book, document, or auto')


@app.post('/ocr/image', response_model=OCRResponse)
async def ocr_image(file: UploadFile = File(...), mode: str = Form('auto')) -> OCRResponse:
    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail='Uploaded image is empty')
    ocr_mode = _image_ocr_mode(mode)
    try:
        data = vision_service.detect_text(image_bytes, ocr_mode)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f'OCR failed: {exc}') from exc
    result_mode = 'MOCK_OCR' if data.get('mock') else ocr_mode
    page = OCRPage(page_number=1, text=data['full_text'], words=data['words'], ocr_mode=result_mode)
    return OCRResponse(source_type='image', ocr_mode=result_mode, full_text=data['full_text'], pages=[page], tokens=_to_tokens(data['full_text']))


@app.post('/ocr/pdf', response_model=OCRResponse)
async def ocr_pdf(file: UploadFile = File(...), mode: str = Form('document'), max_pages: int = Form(3)) -> OCRResponse:
    normalized_mode = mode.lower()
    if normalized_mode not in {'document', 'scanned', 'ocr'}:
        raise HTTPException(status_code=400, detail='PDF mode must be document, scanned, or ocr')
    if max_pages < 1 or max_pages > 20:
        raise HTTPException(status_code=400, detail='max_pages must be between 1 and 20')
    pdf_bytes = await file.read()
    if not pdf_bytes:
        raise HTTPException(status_code=400, detail='Uploaded PDF is empty')
    try:
        embedded_pages = [] if normalized_mode in {'scanned', 'ocr'} else pdf_service.extract_text_pages(pdf_bytes, max_pages=max_pages)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f'Could not read PDF: {exc}') from exc

    pages = []
    texts = []
    modes_used = set()
    page_count = max_pages if not embedded_pages else len(embedded_pages)

    for idx in range(page_count):
        embedded_text = embedded_pages[idx] if idx < len(embedded_pages) else ''
        if embedded_text:
            texts.append(embedded_text)
            modes_used.add('PDF_TEXT_EXTRACTION')
            pages.append(OCRPage(page_number=idx + 1, text=embedded_text, words=[], ocr_mode='PDF_TEXT_EXTRACTION'))
            continue

        try:
            img = pdf_service.render_page(pdf_bytes, idx)
            data = vision_service.detect_text(img, 'DOCUMENT_TEXT_DETECTION')
        except IndexError:
            break
        except Exception as exc:
            raise HTTPException(status_code=502, detail=f'OCR failed on page {idx + 1}: {exc}') from exc
        page_mode = 'MOCK_OCR' if data.get('mock') else 'DOCUMENT_TEXT_DETECTION'
        texts.append(data['full_text'])
        modes_used.add(page_mode)
        pages.append(OCRPage(page_number=idx + 1, text=data['full_text'], words=data['words'], ocr_mode=page_mode))

    full_text = '\n'.join(texts)
    ocr_mode = '+'.join(sorted(modes_used)) if modes_used else 'PDF_EMPTY'
    return OCRResponse(source_type='pdf', ocr_mode=ocr_mode, full_text=full_text, pages=pages, tokens=_to_tokens(full_text))
