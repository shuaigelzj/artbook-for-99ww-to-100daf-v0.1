from pathlib import Path
from collections import Counter, deque
from PIL import Image, ImageDraw, ImageFont
import json, html

OUT=Path(__file__).resolve().parent
FONT='C:/Windows/Fonts/Deng.ttf'
W,H=1360,1490
X,Y,CELL=160,180,80
S=CELL*13
INK='#25313c'
COLORS={'0':'#fff7d6','A':'#e5eef9','B':'#fcebdc','C':'#e4f0e6','D':'#eee6f5'}
grid=[['' for _ in range(13)] for _ in range(13)]
# North arm: a wide top bar plus a narrower stem touching the hub.
seed={(x,z) for z in range(3) for x in range(10)}|{(x,z) for z in range(3,4) for x in range(4,10)}
for k in 'ABCD':
    for x,z in seed:
        assert not grid[z][x],(k,x,z)
        grid[z][x]=k
    seed={(12-z,x) for x,z in seed}
for z in range(4,9):
    for x in range(4,9):
        assert not grid[z][x]
        grid[z][x]='0'
counts=Counter(v for row in grid for v in row)
assert counts=={'A':36,'B':36,'C':36,'D':36,'0':25}
assert all(all(row) for row in grid)
for stage in range(5):
    allowed=set('0'+'ABCD'[:stage])
    cells={(x,z) for z in range(13) for x in range(13) if grid[z][x] in allowed}
    seen={(6,6)};q=deque(seen)
    while q:
        x,z=q.popleft()
        for a,b in [(x-1,z),(x+1,z),(x,z-1),(x,z+1)]:
            if (a,b) in cells and (a,b) not in seen:seen.add((a,b));q.append((a,b))
    assert seen==cells,('disconnected stage',stage)

im=Image.new('RGB',(W,H),'white');d=ImageDraw.Draw(im)
svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">','<rect width="100%" height="100%" fill="white"/>']
def rect(xy,fill):
    a,b,c,e=xy;d.rectangle(xy,fill=fill)
    svg.append(f'<rect x="{a}" y="{b}" width="{c-a}" height="{e-b}" fill="{fill}"/>')
def line(xy,width=1,color=INK):
    a,b,c,e=xy;d.line(xy,fill=color,width=width)
    svg.append(f'<line x1="{a}" y1="{b}" x2="{c}" y2="{e}" stroke="{color}" stroke-width="{width}"/>')
def text(x,y,t,size=27,color=INK):
    d.text((x,y),t,font=ImageFont.truetype(FONT,size),fill=color,anchor='mm')
    svg.append(f'<text x="{x}" y="{y}" text-anchor="middle" dominant-baseline="central" font-family="DengXian, Microsoft YaHei, sans-serif" font-size="{size}" fill="{color}">{html.escape(t)}</text>')

text(680,45,'修订布局：初始区域与整张地图各向外扩一圈',35)
text(680,95,'开局开放整个中央区域；之后按 A → B → C → D 解锁',28)
text(680,141,'方案示意，尚未修改工程；最终所有地块开放',24)
for z,row in enumerate(grid):
    for x,k in enumerate(row):rect((X+x*CELL,Y+z*CELL,X+(x+1)*CELL,Y+(z+1)*CELL),('#ffe19a' if k=='0' and x==6 and z==6 else COLORS[k]))
# 65x65 fine cells; each 13x13 planning cell contains 5x5 actual ground cells.
for i in range(66):
    v=i*S/65
    line((X+v,Y,X+v,Y+S),1,'#c5cdd5')
    line((X,Y+v,X+S,Y+v),1,'#c5cdd5')
for i in range(14):
    v=i*CELL
    line((X+v,Y,X+v,Y+S),1,'#8998a7')
    line((X,Y+v,X+S,Y+v),1,'#8998a7')
# Draw only boundaries between distinct owners, once per edge.
for z,row in enumerate(grid):
    for x,k in enumerate(row):
        if x==0 or grid[z][x-1]!=k:line((X+x*CELL,Y+z*CELL,X+x*CELL,Y+(z+1)*CELL),4)
        if z==0 or grid[z-1][x]!=k:line((X+x*CELL,Y+z*CELL,X+(x+1)*CELL,Y+z*CELL),4)
line((X+S,Y,X+S,Y+S),4);line((X,Y+S,X+S,Y+S),4)
for x,z,number,label,detail in [
 (4.5,1.5,'1 · A区','北侧折臂','900地块'),
 (11.5,4.5,'2 · B区','东侧折臂','900地块'),
 (8.5,11.5,'3 · C区','南侧折臂','900地块'),
 (1.5,8.5,'4 · D区','西侧折臂','900地块')]:
    cx,cy=X+x*CELL,Y+z*CELL
    text(cx,cy-40,number,35);text(cx,cy+4,label,27);text(cx,cy+43,detail,24)
# Core camp has a separate dashed boundary inside the already-open exploration hub.
cx0,cy0=X+6*CELL,Y+6*CELL
for a,b,c,e in [(cx0,cy0,cx0+CELL,cy0),(cx0+CELL,cy0,cx0+CELL,cy0+CELL),(cx0+CELL,cy0+CELL,cx0,cy0+CELL),(cx0,cy0+CELL,cx0,cy0)]:
    for j in range(0,CELL,12):
        t=j/CELL;u=min(j+7,CELL)/CELL
        line((a+(c-a)*t,b+(e-b)*t,a+(c-a)*u,b+(e-b)*u),2)
text(X+6.5*CELL,Y+4.7*CELL,'0 · 初始探索区',30)
text(X+6.5*CELL,Y+5.24*CELL,'25×25地块 · 开局开放',25)
text(X+6.5*CELL,Y+6.34*CELL,'营地核心',20)
text(X+6.5*CELL,Y+6.7*CELL,'5×5',22)
text(X+6.5*CELL,Y+8.15*CELL,'外围600地块：探索／采集',25)
text(680,1265,'完整65×65地块＝4225块；初始625块＋四区各900块',28)
text(680,1310,'细格：50×50 studs；粗格：5×5地块（250×250 studs）',25)
text(680,1353,'初始625块＝营地25块＋外围探索600块，开局同时开放',26)
text(680,1397,'一圈＝四边各加5地块；全图3250×3250，初始区1250×1250 studs',25)
text(680,1442,'四个L形区保持等面积；粗黑线为解锁边界，虚线为营地核心范围',24)
name='05_正方形地图_中心与全图外延一圈'
im.save(OUT/(name+'.png'))
(OUT/(name+'.svg')).write_text('\n'.join(svg+['</svg>']),encoding='utf-8')
plan={'status':'proposal_not_applied','mapGroundCells':[65,65],'groundCellSizeStuds':50,'planningGrid':[13,13],
      'groundCellsPerPlanningCell':[5,5],'rowsNorthToSouth':[''.join(row) for row in grid],
      'unlockOrder':['0','A','B','C','D'],'planningCellCounts':dict(counts),
      'groundCellCounts':{k:v*25 for k,v in counts.items()},'allStagesConnected':True,
      'initialExplorationBoundsInclusive':{'x':[21,45],'z':[21,45]},
      'campCoreBoundsInclusive':{'x':[31,35],'z':[31,35]},
      'initialTotalCells':625,'campCoreCells':25,'initialOuterExplorationCells':600,
      'expansionPerSideGroundCells':5,'mapSideStuds':3250,'initialSideStuds':1250}
(OUT/(name+'.json')).write_text(json.dumps(plan,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'png':str(OUT/(name+'.png')),'counts':plan['groundCellCounts'],'allStagesConnected':True},ensure_ascii=False))
