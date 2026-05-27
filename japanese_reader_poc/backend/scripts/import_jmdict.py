import gzip
import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def open_text(path: Path):
    if path.suffix == '.gz':
        return gzip.open(path, 'rt', encoding='utf-8')
    return path.open('r', encoding='utf-8')


def text_values(parent: ET.Element, tag: str) -> list[str]:
    return [node.text.strip() for node in parent.findall(tag) if node.text and node.text.strip()]


def import_jmdict(source_path: Path, output_path: Path) -> None:
    entries: dict[str, dict] = {}
    with open_text(source_path) as stream:
        for event, elem in ET.iterparse(stream, events=('end',)):
            if elem.tag != 'entry':
                continue

            keys: set[str] = set()
            for keb in elem.findall('./k_ele/keb'):
                if keb.text:
                    keys.add(keb.text.strip())
            for reb in elem.findall('./r_ele/reb'):
                if reb.text:
                    keys.add(reb.text.strip())

            meanings: list[str] = []
            for gloss in elem.findall('./sense/gloss'):
                if gloss.text:
                    meanings.append(gloss.text.strip())
            if keys and meanings:
                value = {'meanings': meanings[:8], 'jlpt': 'unknown'}
                for key in keys:
                    entries.setdefault(key, value)
            elem.clear()

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(entries, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'Wrote {len(entries)} dictionary keys to {output_path}')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit('Usage: python scripts/import_jmdict.py path/to/JMdict_e[.gz] app/data/dictionary_jmdict.json')
    import_jmdict(Path(sys.argv[1]), Path(sys.argv[2]))
