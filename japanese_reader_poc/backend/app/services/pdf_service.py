import fitz


class PDFService:
    def render_pages(self, pdf_bytes: bytes, max_pages: int) -> list[bytes]:
        pages = []
        doc = fitz.open(stream=pdf_bytes, filetype='pdf')
        for i in range(min(max_pages, len(doc))):
            pix = doc[i].get_pixmap(matrix=fitz.Matrix(2, 2))
            pages.append(pix.tobytes('png'))
        return pages
