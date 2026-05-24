from pydantic import BaseModel
from typing import List


class Point(BaseModel):
    x: int
    y: int


class OCRWord(BaseModel):
    text: str
    bounding_box: List[Point]


class OCRPage(BaseModel):
    page_number: int
    text: str
    words: List[OCRWord]


class TokenResult(BaseModel):
    surface: str
    lemma: str
    reading: str
    pos: str
    meaning: str
    jlpt: str


class OCRResponse(BaseModel):
    source_type: str
    ocr_mode: str
    full_text: str
    pages: List[OCRPage]
    tokens: List[TokenResult]
