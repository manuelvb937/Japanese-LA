import fitz


class PDFService:
    def extract_text_pages(self, pdf_bytes: bytes, max_pages: int) -> list[str]:
        pages = []
        doc = fitz.open(stream=pdf_bytes, filetype='pdf')
        try:
            for i in range(min(max_pages, len(doc))):
                pages.append(doc[i].get_text('text').strip())
        finally:
            doc.close()
        return pages

    def render_page(self, pdf_bytes: bytes, page_index: int) -> bytes:
        doc = fitz.open(stream=pdf_bytes, filetype='pdf')
        try:
            pix = doc[page_index].get_pixmap(matrix=fitz.Matrix(2, 2), alpha=False)
            return pix.tobytes('png')
        finally:
            doc.close()

    def render_pages(self, pdf_bytes: bytes, max_pages: int) -> list[bytes]:
        pages = []
        doc = fitz.open(stream=pdf_bytes, filetype='pdf')
        try:
            for i in range(min(max_pages, len(doc))):
                pix = doc[i].get_pixmap(matrix=fitz.Matrix(2, 2), alpha=False)
                pages.append(pix.tobytes('png'))
        finally:
            doc.close()
        return pages
