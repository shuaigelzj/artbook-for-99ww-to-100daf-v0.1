import json
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
root=Path(__file__).resolve().parent
workspace=root.parent.parent
rows=json.loads((root/(sys.argv[1] if len(sys.argv)>1 else 'visual-triage.json')).read_text(encoding='utf-8'))
prefix='primitive' if len(sys.argv)>1 else 'review'
plan=json.loads((workspace/'output/资产图示_全量/plan.json').read_text(encoding='utf-8'))
font=ImageFont.truetype('C:/Windows/Fonts/msyh.ttc',14)
for start in range(0,len(rows),16):
    sheet=Image.new('RGB',(1280,820),'#e8ebec')
    draw=ImageDraw.Draw(sheet)
    for n,r in enumerate(rows[start:start+16]):
        spec=next(p for p in plan if p['start']<int(r['id'][3:])<=p['end'])
        im=Image.open(workspace/'output'/spec['directory']/'images'/(r['id']+'.jpg'))
        im.thumbnail((310,155))
        x=(n%4)*320+5;y=(n//4)*205+5
        sheet.paste(im,(x,y))
        draw.text((x,y+158),r['id']+' '+r['display'][:18],fill='#23342b',font=font)
        draw.text((x,y+180),r['class']+' / '+str(r['parts'])+' parts',fill='#56696c',font=font)
    sheet.save(root/(prefix+'-'+str(start//16+1).zfill(2)+'.jpg'),quality=94)
print(len(rows),'assets;', (len(rows)+15)//16,'sheets')
