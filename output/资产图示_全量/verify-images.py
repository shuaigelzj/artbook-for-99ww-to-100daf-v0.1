import json
import sys
from pathlib import Path
from PIL import Image

directory = Path(sys.argv[1]).resolve()
rows = json.loads((directory / 'capture-records.json').read_text(encoding='utf-8'))
failures = []
for row in rows:
    path = directory / 'images' / (row['id'] + '.jpg')
    with Image.open(path) as original:
        original.load()
        assert original.size == (788, 392), (row['id'], original.size)
        small = original.convert('RGB').resize((100, 50))
        white_fraction = sum(min(pixel) > 245 for pixel in small.get_flattened_data()) / 5000
        if white_fraction > .97:
            failures.append({'id': row['id'], 'whiteFraction': round(white_fraction, 4)})
        if row.get('renderMode') == 'Studio ViewportFrame':
            crop = original.convert('RGB').crop((0, 0, 788, 340)).resize((197, 85))
            colors = crop.getcolors(197 * 85)
            if colors and max(count for count, _ in colors) / (197 * 85) > .9998:
                failures.append({'id': row['id'], 'reason': 'uniform viewport without model pixels'})
print(json.dumps({'checked': len(rows), 'whiteFrames': failures}, ensure_ascii=False))
if failures:
    sys.exit(1)
