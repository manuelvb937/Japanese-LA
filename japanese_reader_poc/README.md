# Japanese Reader PoC (Flutter + FastAPI)

A proof-of-concept Japanese learning app with secure OCR architecture:
- Flutter iOS frontend (no secrets in app)
- FastAPI backend calls Google Cloud Vision
- SudachiPy tokenization
- mock JSON dictionary lookup

## Monorepo structure

```text
japanese_reader_poc/
  frontend_flutter/
  backend/
```

## Security model

- **Do not embed API keys or service account files in Flutter.**
- Backend authenticates to Google Cloud Vision via ADC or `GOOGLE_APPLICATION_CREDENTIALS`.

## Backend setup

```bash
cd japanese_reader_poc/backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

Authenticate Google Cloud Vision locally:

```bash
gcloud auth application-default login
gcloud auth application-default set-quota-project PROJECT_ID
```

Run backend:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Health check:

```bash
curl http://127.0.0.1:8000/health
```

### Test one image

```bash
curl -X POST http://127.0.0.1:8000/ocr/image \
  -F "file=@/absolute/path/to/sample.jpg" \
  -F "mode=sign"
```

### Test one PDF

```bash
curl -X POST http://127.0.0.1:8000/ocr/pdf \
  -F "file=@/absolute/path/to/sample.pdf" \
  -F "mode=document" \
  -F "max_pages=3"
```

## Flutter setup

```bash
cd japanese_reader_poc/frontend_flutter
flutter pub get
flutter run -d ios --dart-define=BACKEND_URL=http://127.0.0.1:8000
```

For iOS simulator, keep backend URL configurable via `--dart-define=BACKEND_URL=...`.

## PoC user flow implemented

1. Home screen -> Scan Japanese
2. Scan options (photo, image, PDF, scanned PDF, sign/menu)
3. Image crop/resize before OCR
4. OCR loading screen
5. Reader screen with tappable tokens + word detail bottom sheet
6. Save vocabulary locally (SharedPreferences)

## TODO (future improvements)

- Replace mock dictionary with JMdict-backed lookup.
- Add better sentence-preserving token rendering and OCR line mapping.
- Persist recent scans and OCR artifacts.
- Add SRS/quiz loop and export formats.
- Improve iOS-native crop experience and camera permissions messaging.
- Add integration tests for OCR endpoints and Flutter widget tests.
