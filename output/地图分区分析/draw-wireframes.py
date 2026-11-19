from pathlib import Path
import math, html
from PIL import Image, ImageDraw, ImageFont

OUT=Path(__file__).resolve().parent
FONT='C:/Windows/Fonts/Deng.ttf'
INK='#20262c'
GRID='#d9dde1'

class Figure:
    def __init__(self,w,h):
        self.w,self.h=w,h
        self.im=Image.new('RGB',(w,h),'white')
        self.d=ImageDraw.Draw(self.im)
        self.svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">',f'<rect width="{w}" height="{h}" fill="white"/>']
    def line(self,xy,color=INK,width=2,dash=None):
        x1,y1,x2,y2=xy
        if dash:
            length=math.hypot(x2-x1,y2-y1)
            t=0
            while t<length:
                end=min(t+dash[0],length)
                self.d.line((x1+(x2-x1)*t/length,y1+(y2-y1)*t/length,x1+(x2-x1)*end/length,y1+(y2-y1)*end/length),fill=color,width=width)
                t+=sum(dash)
        else:self.d.line(xy,fill=color,width=width)
        ds=f' stroke-dasharray="{dash[0]} {dash[1]}"' if dash else ''
        self.svg.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{color}" stroke-width="{width}"{ds}/>')
    def rect(self,xy,color=INK,width=2,dash=None):
        x1,y1,x2,y2=xy
        for p in [(x1,y1,x2,y1),(x2,y1,x2,y2),(x2,y2,x1,y2),(x1,y2,x1,y1)]:self.line(p,color,width,dash)
    def text(self,xy,text,size=27,anchor='mm',color=INK):
        self.d.text(xy,text,font=ImageFont.truetype(FONT,size),fill=color,anchor=anchor)
        align='middle' if anchor[0]=='m' else 'start'
        self.svg.append(f'<text x="{xy[0]}" y="{xy[1]}" font-family="DengXian, Microsoft YaHei, sans-serif" font-size="{size}" text-anchor="{align}" dominant-baseline="central" fill="{color}">{html.escape(text)}</text>')
    def save(self,name):
        self.im.save(OUT/(name+'.png'))
        (OUT/(name+'.svg')).write_text('\n'.join(self.svg+['</svg>']),encoding='utf-8')

X,Y,S=165,160,770
f=Figure(1100,1100)
f.text((550,43),'地图固定分区：6圈方形等级区',35)
f.text((550,91),'按当前配置计算；不是6个独立岛，也不是6种地貌',25)
for n in range(12):
    p=n*S/11
    f.line((X+p,Y,X+p,Y+S),GRID,1)
    f.line((X,Y+p,X+S,Y+p),GRID,1)
for lv in range(6,0,-1):
    inset=(6-lv)*S/11
    f.rect((X+inset,Y+inset,X+S-inset,Y+S-inset),width=3)
    cy=Y+inset+S/22
    if lv==1:
        f.text((550,cy-12),'1级区',22)
        f.text((550,cy+16),'营地',20)
    else:f.text((550,cy),f'{lv}级区',26)
f.text((550,129),'全图宽 2750 studs',24)
f.text((550,978),'每个细线方格：250×250 studs（5×5个基础地块）',25)
f.text((550,1020),'全图：11×11个大格＝55×55个基础地块',25)
f.text((550,1061),'各圈厚1大格；中心1级区为1大格',25)
f.save('01_六级分区线框图')

g=Figure(1100,1160)
g.text((550,43),'地貌与点位叠加：一种符合规则的布局示意',33)
g.text((550,91),'非当前运行地图快照；位置随机，边界会裁切和跳格',25)
g.rect((X,Y,X+S,Y+S),width=3)
step=S/55
def box(x1,z1,x2,z2,**kw):
    # Inclusive 1-based ground-cell coordinates -> exact outer envelope.
    g.rect((X+(x1-1)*step,Y+(z1-1)*step,X+x2*step,Y+z2*step),**kw)
def center(x,z):return X+(x-.5)*step,Y+(z-.5)*step
box(1,1,23,23,dash=(12,7))
box(32,1,55,23,dash=(12,7))
for x,z,label in [(11.5,10,'沼泽'),(43.5,10,'雪原／雪山')]:
    cx,cy=center(x,z)
    g.text((cx,cy),label,31)
    g.text((cx,cy+43),'角落候选点生成',22)
box(26,26,30,30,width=3)
cx,cy=center(28,28)
g.text((cx,cy-11),'营地',23)
g.text((cx,cy+16),'1级区',20)
box(7,27,13,33,dash=(5,5))
cx,cy=center(10,30)
g.text((cx,cy),'山丘',25)
box(39,24,47,32,dash=(5,5))
cx,cy=center(43,28)
g.text((cx,cy-14),'下沉盆地',23)
g.text((cx,cy+16),'／事件区',21)
z=40
cy=center(1,z)[1]
g.line((X,cy-5,X+S,cy-5),width=2)
g.line((X,cy+5,X+S,cy+5),width=2)
for j in range(55):
    cx=X+(j+.5)*step
    g.line((cx,cy-10,cx,cy+10),width=1)
g.text((550,cy+40),'铁路走廊（此例取 z＝40）',25)
g.text((550,Y+S-51),'普通平原填充剩余可用空间',27)
g.line((165,983,230,983),dash=(12,7))
g.text((250,983),'沼泽／雪原的外包络，实际边缘不规则',24,anchor='lm')
g.line((165,1024,230,1024),dash=(5,5))
g.text((250,1024),'局部地形；建筑与资源点之后分布',24,anchor='lm')
g.text((550,1080),'沼泽、雪原均可跨越多个等级圈；铁路也可横穿等级圈',25)
g.text((550,1122),'雪山属于雪原；洞穴／Boss／车厢战场另在不同高度摆放',24)
g.save('02_地貌叠加线框示意图')
print('Created 2 PNG + 2 SVG wireframes')
