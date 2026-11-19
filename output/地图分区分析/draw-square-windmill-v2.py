from pathlib import Path
from collections import Counter, deque
from PIL import Image, ImageDraw, ImageFont
import json, html

OUT=Path(__file__).resolve().parent
FONT='C:/Windows/Fonts/Deng.ttf'
W,H=1200,1330
X,Y,CELL=160,180,80
S=CELL*11
INK='#25313c'
COLORS={'0':'#fff7d6','A':'#e5eef9','B':'#fcebdc','C':'#e4f0e6','D':'#eee6f5'}
grid=[['' for _ in range(11)] for _ in range(11)]
# North arm: a wide top bar plus a narrower stem touching the hub.
seed={(x,z) for z in range(3) for x in range(8)}|{(x,z) for z in range(3,4) for x in range(4,8)}
for k in 'ABCD':
    for x,z in seed:
        assert not grid[z][x],(k,x,z)
        grid[z][x]=k
    seed={(10-z,x) for x,z in seed}
for z in range(4,7):
    for x in range(4,7):
        assert not grid[z][x]
        grid[z][x]='0'
counts=Counter(v for row in grid for v in row)
assert counts=={'A':28,'B':28,'C':28,'D':28,'0':9}
assert all(all(row) for row in grid)
for stage in range(5):
    allowed=set('0'+'ABCD'[:stage])
    cells={(x,z) for z in range(11) for x in range(11) if grid[z][x] in allowed}
    seen={(5,5)};q=deque(seen)
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

text(600,45,'修订布局：营地核心＋外围初始探索区',35)
text(600,95,'开局开放整个中央区域；之后按 A → B → C → D 解锁',28)
text(600,141,'方案示意，尚未修改工程；最终所有地块开放',24)
for z,row in enumerate(grid):
    for x,k in enumerate(row):rect((X+x*CELL,Y+z*CELL,X+(x+1)*CELL,Y+(z+1)*CELL),('#ffe19a' if k=='0' and x==5 and z==5 else COLORS[k]))
# 55x55 fine cells; each 11x11 planning cell contains 5x5 actual ground cells.
for i in range(56):
    v=i*S/55
    line((X+v,Y,X+v,Y+S),1,'#c5cdd5')
    line((X,Y+v,X+S,Y+v),1,'#c5cdd5')
for i in range(12):
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
 (3.5,1.5,'1 · A区','北侧折臂','700地块'),
 (9.5,3.5,'2 · B区','东侧折臂','700地块'),
 (7.5,9.5,'3 · C区','南侧折臂','700地块'),
 (1.5,7.5,'4 · D区','西侧折臂','700地块')]:
    cx,cy=X+x*CELL,Y+z*CELL
    text(cx,cy-40,number,35);text(cx,cy+4,label,27);text(cx,cy+43,detail,24)
# Core camp has a separate dashed boundary inside the already-open exploration hub.
cx0,cy0=X+5*CELL,Y+5*CELL
for a,b,c,e in [(cx0,cy0,cx0+CELL,cy0),(cx0+CELL,cy0,cx0+CELL,cy0+CELL),(cx0+CELL,cy0+CELL,cx0,cy0+CELL),(cx0,cy0+CELL,cx0,cy0)]:
    for j in range(0,CELL,12):
        t=j/CELL;u=min(j+7,CELL)/CELL
        line((a+(c-a)*t,b+(e-b)*t,a+(c-a)*u,b+(e-b)*u),2)
text(X+5.5*CELL,Y+4.4*CELL,'0 · 初始探索区',25)
text(X+5.5*CELL,Y+4.76*CELL,'15×15地块',22)
text(X+5.5*CELL,Y+5.34*CELL,'营地核心',20)
text(X+5.5*CELL,Y+5.7*CELL,'5×5',22)
text(X+5.5*CELL,Y+6.55*CELL,'外围可探索／采集',22)
text(600,1105,'完整55×55地块＝3025块；初始225块＋四区各700块',28)
text(600,1150,'细格：50×50 studs；粗格：5×5地块（250×250 studs）',25)
text(600,1193,'初始225块＝营地25块＋外围探索200块，开局同时开放',26)
text(600,1237,'初始范围750×750 studs；营地每侧增加250 studs探索纵深',25)
text(600,1282,'四个L形区保持等面积；粗黑线为解锁边界，虚线为营地核心范围',24)
name='04_正方形地图_扩大初始探索区方案'
im.save(OUT/(name+'.png'))
(OUT/(name+'.svg')).write_text('\n'.join(svg+['</svg>']),encoding='utf-8')
plan={'status':'proposal_not_applied','mapGroundCells':[55,55],'groundCellSizeStuds':50,'planningGrid':[11,11],
      'groundCellsPerPlanningCell':[5,5],'rowsNorthToSouth':[''.join(row) for row in grid],
      'unlockOrder':['0','A','B','C','D'],'planningCellCounts':dict(counts),
      'groundCellCounts':{k:v*25 for k,v in counts.items()},'allStagesConnected':True,
      'initialExplorationBoundsInclusive':{'x':[21,35],'z':[21,35]},
      'campCoreBoundsInclusive':{'x':[26,30],'z':[26,30]},
      'initialTotalCells':225,'campCoreCells':25,'initialOuterExplorationCells':200}
(OUT/(name+'.json')).write_text(json.dumps(plan,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'png':str(OUT/(name+'.png')),'counts':plan['groundCellCounts'],'allStagesConnected':True},ensure_ascii=False))
