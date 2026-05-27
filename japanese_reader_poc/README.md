# Japanese Reader PoC

A proof-of-concept Japanese learning app with a secure OCR architecture:

- Flutter frontend for iOS and Windows desktop
- FastAPI backend that calls Google Cloud Vision
- SudachiPy tokenization, with a simple fallback tokenizer for local development
- JSON dictionary lookup with optional JMdict import
- PDF rendering with PyMuPDF

The Flutter app never stores Google Cloud secrets. It calls the backend, and the backend authenticates with Application Default Credentials or `GOOGLE_APPLICATION_CREDENTIALS`.

## Structure

```text
japanese_reader_poc/
  frontend_flutter/
  backend/
```

## Backend Setup On Windows

The helper script uses Python 3.10 because some backend packages include compiled wheels. If a `.venv` was created with another Python version, the script recreates it with Python 3.10.

```powershell
cd C:\Users\MANUE\Desktop\Japanese-LA\japanese_reader_poc\backend
py -3.10 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
Copy-Item .env.example .env
```

Authenticate Google Cloud Vision locally:

```powershell
gcloud auth application-default login
gcloud auth application-default set-quota-project PROJECT_ID
```

Run the backend:

```powershell
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Or use the helper script:

```powershell
.\run_backend.ps1
```

To test the backend/frontend loop without Google credentials, start with mock OCR text:

```powershell
.\run_backend.ps1 -Mock
```

Mock mode always returns sample text and the API labels results as `MOCK_OCR`. Use it only for UI testing. For real book/photo scans, stop the backend and run `.\run_backend.ps1` without `-Mock`. The helper script clears mock environment variables when `-Mock` is not used.

Health check:

```powershell
curl.exe http://127.0.0.1:8000/health
```

## Backend Setup On macOS/Linux

```bash
cd japanese_reader_poc/backend
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
cp .env.example .env
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

## Test OCR Endpoints

Image:

```powershell
curl.exe -X POST http://127.0.0.1:8000/ocr/image `
  -F "file=@C:\absolute\path\sample.jpg" `
  -F "mode=sign"
```

PDF:

```powershell
curl.exe -X POST http://127.0.0.1:8000/ocr/pdf `
  -F "file=@C:\absolute\path\sample.pdf" `
  -F "mode=document" `
  -F "max_pages=3"
```

Selectable text PDFs are read directly first. Pages without embedded text fall back to Google Vision `DOCUMENT_TEXT_DETECTION`. Use `mode=scanned` to force OCR for every page.

## Flutter Setup

Flutter is currently installed at:

```text
C:\Users\MANUE\Desktop\flutter
```

If `flutter` is not on `PATH`, use the full path:

```powershell
C:\Users\MANUE\Desktop\flutter\bin\flutter.bat --version
```

Install packages from the frontend folder:

```powershell
cd C:\Users\MANUE\Desktop\Japanese-LA\japanese_reader_poc\frontend_flutter
C:\Users\MANUE\Desktop\flutter\bin\flutter.bat pub get
```

This repository currently stores the app source. If native platform folders are missing after cloning, generate them once.

On Windows:

```powershell
flutter create --platforms=windows .
flutter pub get
```

On macOS for iOS:

```bash
flutter create --platforms=ios .
flutter pub get
```

Run on Windows desktop:

```powershell
flutter config --enable-windows-desktop
flutter run -d windows --dart-define=BACKEND_URL=http://127.0.0.1:8000
```

Run in Chrome on Windows. This does not require the Visual Studio C++ desktop toolchain:

```powershell
C:\Users\MANUE\Desktop\flutter\bin\flutter.bat run -d chrome --dart-define=BACKEND_URL=http://127.0.0.1:8000
```

Run on iOS simulator from macOS:

```bash
flutter run -d ios --dart-define=BACKEND_URL=http://127.0.0.1:8000
```

For a physical phone, replace `127.0.0.1` with your computer's LAN IP, for example:

```powershell
flutter run --dart-define=BACKEND_URL=http://192.168.1.25:8000
```

## Daily Local Run

Open two PowerShell windows.

Terminal 1, backend with real Google Cloud Vision OCR:

```powershell
cd C:\Users\MANUE\Desktop\Japanese-LA\japanese_reader_poc\backend
.\run_backend.ps1
```

Leave it open after it prints:

```text
Uvicorn running on http://127.0.0.1:8000
```

If you only want to test the UI without Google credentials, use `.\run_backend.ps1 -Mock`. The reader will show a warning and label the scan as `MOCK_OCR`. Existing scans saved while mock mode was on remain mock scans; re-scan the page after starting the real backend.

Terminal 2, Flutter app in Chrome:

```powershell
cd C:\Users\MANUE\Desktop\Japanese-LA\japanese_reader_poc\frontend_flutter
C:\Users\MANUE\Desktop\flutter\bin\flutter.bat run -d chrome --dart-define=BACKEND_URL=http://127.0.0.1:8000
```

For Windows desktop after Visual Studio Build Tools is complete:

```powershell
cd C:\Users\MANUE\Desktop\Japanese-LA\japanese_reader_poc\frontend_flutter
C:\Users\MANUE\Desktop\flutter\bin\flutter.bat run -d windows --dart-define=BACKEND_URL=http://127.0.0.1:8000
```

## Projects Workflow

Projects let you group scans by book, manga, course, or any reading source.

Example:

1. Open **Projects**.
2. Create a project such as `Water Magician`.
3. Open the project.
4. Tap **Add Page**.
5. Scan or choose an image/PDF.
6. The scan is saved inside that project and can be reopened later.

The same scan also appears in **Recent scans** with its project label.

Build a Windows `.exe`:

```powershell
cd C:\Users\MANUE\Desktop\Japanese-LA\japanese_reader_poc\frontend_flutter
C:\Users\MANUE\Desktop\flutter\bin\flutter.bat build windows --dart-define=BACKEND_URL=http://127.0.0.1:8000
```

The built app is written to:

```text
frontend_flutter\build\windows\x64\runner\Release\japanese_reader_poc.exe
```

## Live OCR Status

Google Cloud Vision is wired through the backend and has been tested with `Book1.jpeg` using `DOCUMENT_TEXT_DETECTION`.

The test returned:

- OCR mode: `DOCUMENT_TEXT_DETECTION`
- Extracted text length: 803 characters
- Tokenization: SudachiPy tokens returned with lemma, reading, POS, dictionary meaning, and JLPT fallback

If a scan shows only `日本語を勉強します。`, the backend is running in mock mode. Restart the backend without `-Mock` to use Google Cloud Vision.

Example OCR sample:

```text
そう、いつも通りなら、決して難しい仕事ではなかった...
待たされること三十分。
「お待たせいたしました。これから公爵邸の方に移動していただきます...
```

## Testing On iPhone

Native iPhone builds require macOS, Xcode, CocoaPods, and an Apple developer account. You cannot build or deploy the native iOS Flutter app directly from Windows.

Options:

- Use a Mac: clone this repo, install Flutter and Xcode, run `flutter create --platforms=ios .`, then run on an iPhone or iOS simulator.
- Test the web build from your iPhone: run the backend on `0.0.0.0`, run Flutter web on a LAN-visible port, and open the URL in Safari.
- Use a cloud Mac build service later, such as Codemagic or GitHub Actions on macOS, to produce an iOS build/TestFlight artifact.

For iPhone web testing on the same Wi-Fi network:

```powershell
ipconfig
```

Find your computer's IPv4 address, for example `192.168.1.25`.

Backend:

```powershell
cd C:\Users\MANUE\Desktop\Japanese-LA\japanese_reader_poc\backend
.\run_backend.ps1 -HostName 0.0.0.0
```

Use `.\run_backend.ps1 -Mock -HostName 0.0.0.0` only for UI testing without real OCR.

Flutter web:

```powershell
cd C:\Users\MANUE\Desktop\Japanese-LA\japanese_reader_poc\frontend_flutter
C:\Users\MANUE\Desktop\flutter\bin\flutter.bat run -d chrome --web-hostname 0.0.0.0 --web-port 5000 --dart-define=BACKEND_URL=http://192.168.1.25:8000
```

Then open this on the iPhone:

```text
http://192.168.1.25:5000
```

If the phone cannot connect, allow Python/Flutter through Windows Firewall for private networks.

## Dictionary Upgrade

By default the backend loads:

```text
backend\app\data\dictionary_mock.json
backend\app\data\jlpt_mock.json
```

If this file exists, it is preferred automatically:

```text
backend\app\data\dictionary_jmdict.json
```

To apply JMdict:

1. Download the English-only JMdict file from the EDRDG FTP mirror.
2. Run the importer.
3. Restart the backend.

```powershell
cd C:\Users\MANUE\Desktop\Japanese-LA\japanese_reader_poc\backend
curl.exe -L http://ftp.edrdg.org/pub/Nihongo/JMdict_e.gz -o app\data\JMdict_e.gz
.\.venv\Scripts\python.exe scripts\import_jmdict.py app\data\JMdict_e.gz app\data\dictionary_jmdict.json
.\run_backend.ps1
```

The backend automatically prefers `dictionary_jmdict.json` on startup. You do not need to change Flutter code.

To convert a manually downloaded JMdict XML or gzipped XML file into the JSON format:

```powershell
cd C:\Users\MANUE\Desktop\Japanese-LA\japanese_reader_poc\backend
.\.venv\Scripts\python.exe scripts\import_jmdict.py C:\path\to\JMdict_e.gz app\data\dictionary_jmdict.json
```

The bundled dictionary is a starter dictionary, not full JMdict. The JLPT file is a small local overlay used to fill known levels for matching entries. The full JMdict data file is not committed to this PoC because it is large and should be managed intentionally with its license/attribution.

JMdict/EDICT data is maintained by the Electronic Dictionary Research and Development Group. The EDRDG license statement says the relevant dictionary files are under Creative Commons Attribution-ShareAlike 4.0, and app/software usage must acknowledge the source, provide links or copies of the documentation/license, and keep the data reasonably up to date. If we bundle JMdict in the app/backend, add an in-app **Sources/About** screen and documentation attribution before distributing builds.

Useful links:

- EDRDG license statement: https://www.edrdg.org/edrdg/licence.html
- CC BY-SA 4.0 deed: https://creativecommons.org/licenses/by-sa/4.0/

## Tests

Backend:

```powershell
cd C:\Users\MANUE\Desktop\Japanese-LA\japanese_reader_poc\backend
.\.venv\Scripts\python.exe -m pytest
```

Flutter:

```powershell
cd C:\Users\MANUE\Desktop\Japanese-LA\japanese_reader_poc\frontend_flutter
C:\Users\MANUE\Desktop\flutter\bin\flutter.bat analyze
C:\Users\MANUE\Desktop\flutter\bin\flutter.bat test
```

## Implemented PoC Flow

1. Home screen with a polished Japanese-learning style.
2. Scan options for camera, image, PDF, scanned PDF, and sign/menu.
3. Cross-platform Flutter crop screen using `crop_your_image`.
4. Loading screen while OCR runs.
5. Reader screen with original text, vertical reading view, and line-preserving tappable token view.
6. Word detail bottom sheet with dictionary-style fields.
7. Local vocabulary storage with `shared_preferences`.
8. Local recent scans storage with reopen support.
9. Selectable PDF text extraction before OCR fallback.
10. Local projects for grouping pages/scans by book or source.
11. Animated press/hover cards, primary buttons, and route transitions.
12. More visible token underlines for easier word separation.
13. Starter dictionary plus JLPT overlay, with automatic `dictionary_jmdict.json` loading when imported.
14. Paginated vertical reader with tappable word markers.
15. Delete controls for recent scans, project pages, projects, and vocabulary.
16. Vocabulary mini game using saved words.

## Notes

- No Google Cloud keys or service account files belong in Flutter.
- Keep `.env` and service account JSON files out of git.
- `MOCK_OCR_TEXT` is only for local PoC testing.
- Windows camera capture is intentionally not enabled yet; choose an image file on desktop.

## TODO

- Download/import full JMdict data with attribution if this becomes more than a PoC.
- Add SRS review and export formats.
- Improve OCR bounding-box overlays and true vertical Japanese typesetting.
- Add iOS native build/signing on macOS or a cloud Mac CI service.
- Add project thumbnails from scanned page images.
