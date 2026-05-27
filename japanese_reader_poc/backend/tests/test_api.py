import fitz
from fastapi.testclient import TestClient

from app import main
from app.services.vision_service import _env_truthy


client = TestClient(main.app)


def test_health_reports_dictionary_source():
    response = client.get('/health')

    assert response.status_code == 200
    assert response.json()['status'] == 'ok'
    assert 'dictionary' in response.json()


def test_mock_ocr_requires_explicit_flag(monkeypatch):
    monkeypatch.setenv('MOCK_OCR_TEXT', 'stale sample')
    monkeypatch.delenv('MOCK_OCR', raising=False)

    assert not _env_truthy('MOCK_OCR')


def test_image_uses_text_detection_for_sign(monkeypatch):
    calls = []

    def fake_detect_text(image_bytes: bytes, mode: str) -> dict:
        calls.append(mode)
        return {'full_text': '日本語を勉強します。', 'words': []}

    monkeypatch.setattr(main.vision_service, 'detect_text', fake_detect_text)

    response = client.post(
        '/ocr/image',
        data={'mode': 'sign'},
        files={'file': ('sample.png', b'image-bytes', 'image/png')},
    )

    assert response.status_code == 200
    data = response.json()
    assert calls == ['TEXT_DETECTION']
    assert data['ocr_mode'] == 'TEXT_DETECTION'
    assert data['tokens']


def test_image_labels_mock_ocr(monkeypatch):
    def fake_detect_text(image_bytes: bytes, mode: str) -> dict:
        return {'full_text': '日本語を勉強します。', 'words': [], 'mock': True}

    monkeypatch.setattr(main.vision_service, 'detect_text', fake_detect_text)

    response = client.post(
        '/ocr/image',
        data={'mode': 'book'},
        files={'file': ('sample.png', b'image-bytes', 'image/png')},
    )

    assert response.status_code == 200
    data = response.json()
    assert data['ocr_mode'] == 'MOCK_OCR'
    assert data['pages'][0]['ocr_mode'] == 'MOCK_OCR'


def test_dictionary_uses_jlpt_overlay():
    entry = main.dictionary_service.lookup('中央', '中央')

    assert entry['jlpt'] == 'N3'
    assert entry['meaning'] != 'Dictionary entry not found yet'


def test_pdf_extracts_embedded_text_before_ocr(monkeypatch):
    def fail_if_called(image_bytes: bytes, mode: str) -> dict:
        raise AssertionError('OCR should not run for selectable text PDFs')

    monkeypatch.setattr(main.vision_service, 'detect_text', fail_if_called)
    pdf_bytes = _pdf_with_text('Selectable PDF text should not need OCR.')

    response = client.post(
        '/ocr/pdf',
        data={'mode': 'document', 'max_pages': '1'},
        files={'file': ('text.pdf', pdf_bytes, 'application/pdf')},
    )

    assert response.status_code == 200
    data = response.json()
    assert data['ocr_mode'] == 'PDF_TEXT_EXTRACTION'
    assert 'Selectable PDF text' in data['full_text']


def test_scanned_pdf_mode_forces_ocr(monkeypatch):
    calls = []

    def fake_detect_text(image_bytes: bytes, mode: str) -> dict:
        calls.append(mode)
        return {'full_text': '日本語', 'words': []}

    monkeypatch.setattr(main.vision_service, 'detect_text', fake_detect_text)
    pdf_bytes = _pdf_with_text('Selectable text that should be ignored in scanned mode')

    response = client.post(
        '/ocr/pdf',
        data={'mode': 'scanned', 'max_pages': '1'},
        files={'file': ('scan.pdf', pdf_bytes, 'application/pdf')},
    )

    assert response.status_code == 200
    assert calls == ['DOCUMENT_TEXT_DETECTION']
    assert response.json()['ocr_mode'] == 'DOCUMENT_TEXT_DETECTION'


def _pdf_with_text(text: str) -> bytes:
    doc = fitz.open()
    page = doc.new_page()
    page.insert_text((72, 72), text)
    pdf_bytes = doc.tobytes()
    doc.close()
    return pdf_bytes
