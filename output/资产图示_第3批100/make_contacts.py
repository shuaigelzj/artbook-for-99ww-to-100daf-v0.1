import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parent
rows = sorted(json.loads((root / 'capture-records.json').read_text(encoding='utf-8')), key=lambda r:r['id'])
font = ImageFont.truetype('C:/Windows/Fonts/msyh.ttc', 14)
for start in range(0, len(rows), 20):
    group = rows[start:start+20]
    sheet = Image.new('RGB', (1280, 1100), '#eae5dc')
    draw = ImageDraw.Draw(sheet)
    for index, row in enumerate(group):
        image = Image.open(root / 'images' / (row['id'] + '.jpg')).convert('RGB')
        assert image.size == (788,392), (row['id'], image.size)
        image.thumbnail((310,155))
        x=(index%4)*320+5; y=(index//4)*220+5
        sheet.paste(image,(x,y))
        draw.text((x,y+160),row['id']+' '+row['name'][:18],font=font,fill='#24372e')
        draw.text((x,y+185),row['method'],font=font,fill='#6a655d')
    file='contact-'+group[0]['id']+'-'+group[-1]['id']+'.jpg'
    sheet.save(root/file,quality=92)
print('Contact sheets:', len(rows), 'images checked')
