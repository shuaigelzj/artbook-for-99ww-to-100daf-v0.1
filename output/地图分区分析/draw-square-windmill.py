from pathlib import Path
from collections import Counter, deque
from PIL import Image, ImageDraw, ImageFont
import json, html

OUT=Path(__file__).resolve().parent
FONT='C:/Windows/Fonts/Deng.ttf'
W,H=1200,1290
X,Y,CELL=160,180,80
S=CELL*11
INK='#25313c'
COLORS={'0':'#fff7d6','A':'#e5eef9','B':'#fcebdc','C':'#e4f0e6','D':'#eee6f5'}
grid=[['' for _ in range(11)] for _ in range(11)]
# North arm: a wide top bar plus a narrower stem touching the hub.
seed={(x,z) for z in range(3) for x in range(8)}|{(x,z) for z in range(3,5) for x in range(5,8)}
for k in 'ABCD':
    for x,z in seed:
        assert not grid[z][x],(k,x,z)
        grid[z][x]=k
    seed={(10-z,x) for x,z in seed}
assert not grid[5][5]
grid[5][5]='0'
counts=Counter(v for row in grid for v in row)
assert counts=={'A':30,'B':30,'C':30,'D':30,'0':1}
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

text(600,45,'完整正方形地图：中央起点＋四个L形区域',35)
text(600,95,'解锁顺序：0中央 → 1北A → 2东B → 3南C → 4西D',28)
text(600,141,'方案示意，尚未修改工程；最终所有地块开放',24)
for z,row in enumerate(grid):
    for x,k in enumerate(row):rect((X+x*CELL,Y+z*CELL,X+(x+1)*CELL,Y+(z+1)*CELL),COLORS[k])
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
 (3.5,1.5,'1 · A区','北侧折臂','750地块'),
 (9.5,3.5,'2 · B区','东侧折臂','750地块'),
 (7.5,9.5,'3 · C区','南侧折臂','750地块'),
 (1.5,7.5,'4 · D区','西侧折臂','750地块')]:
    cx,cy=X+x*CELL,Y+z*CELL
    text(cx,cy-40,number,35);text(cx,cy+4,label,27);text(cx,cy+43,detail,24)
text(X+5.5*CELL,Y+5.5*CELL-13,'0',26)
text(X+5.5*CELL,Y+5.5*CELL+17,'营地',23)
text(600,1105,'完整55×55地块＝3025块；中央25块＋四区各750块',28)
text(600,1150,'细格：50×50 studs；粗格：5×5地块（250×250 studs）',25)
text(600,1193,'四个L形区旋转对称，完整拼成正方形，无缺角、无空白',26)
text(600,1237,'粗黑线表示解锁区域边界；地形与建筑后续在各区内部生成',24)
name='03_正方形地图_卍形顺时针分区方案'
im.save(OUT/(name+'.png'))
(OUT/(name+'.svg')).write_text('\n'.join(svg+['</svg>']),encoding='utf-8')
plan={'status':'proposal_not_applied','mapGroundCells':[55,55],'groundCellSizeStuds':50,'planningGrid':[11,11],
      'groundCellsPerPlanningCell':[5,5],'rowsNorthToSouth':[''.join(row) for row in grid],
      'unlockOrder':['0','A','B','C','D'],'planningCellCounts':dict(counts),
      'groundCellCounts':{k:v*25 for k,v in counts.items()},'allStagesConnected':True}
(OUT/(name+'.json')).write_text(json.dumps(plan,ensure_ascii=False,indent=2),encoding='utf-8')
(OUT/(name+'.md')).write_text('''# 正方形地图的卍形顺时针分区方案

这是拟议布局，尚未修改Studio工程。保持现有55×55个基础地块、2750×2750 studs的完整正方形外轮廓。

![最终布局地块](03_正方形地图_卍形顺时针分区方案.png)

| 阶段 | 区域 | 规划大格数 | 基础地块数 |
| --- | --- | ---: | ---: |
| 初始0 | 中央营地，5×5基础地块 | 1 | 25 |
| 1 | A北侧L形区 | 30 | 750 |
| 2 | B东侧L形区 | 30 | 750 |
| 3 | C南侧L形区 | 30 | 750 |
| 4 | D西侧L形区 | 30 | 750 |
| 合计 | 完整正方形 | 121 | 3025 |

四个L形区旋转对称，每区都直接邻接中央营地。按A→B→C→D依次开放，已开放区域保持开放。颜色表示解锁区域，不代表已确定的地貌主题；粗黑边是分区边界，不代表正式场景已经设置墙体或道路。

最终布局按11×11规划大格表示如下，每个字母格包含5×5个基础地块：

```text
'''+ '\n'.join(' '.join(row) for row in grid)+'''
```

已验证121个规划格全部唯一归属、总数3025个基础地块，并且初始及每一步解锁后的区域均通过四邻接连通。

[可编辑SVG](03_正方形地图_卍形顺时针分区方案.svg) · [格子归属JSON](03_正方形地图_卍形顺时针分区方案.json)
''',encoding='utf-8')
print(json.dumps({'png':str(OUT/(name+'.png')),'counts':plan['groundCellCounts'],'allStagesConnected':True},ensure_ascii=False))
