import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const dir=path.dirname(fileURLToPath(import.meta.url));
const target=path.join(dir,'废土环境设定集_回填要求与对照表_合并版.md');
if(fs.existsSync(target))throw new Error('合并版已存在；为保护回填内容，拒绝覆盖。');
const read=name=>fs.readFileSync(path.join(dir,name),'utf8').replace(/\r\n/g,'\n').trim();
const sections=[
 ['01_全局视觉设定.md','global','全局视觉设定'],
 ['05_生图规格与差异覆盖.md','image-spec','生图规格、差异覆盖与填写示例'],
 ['02_地貌与地形对照表.md','terrain','地貌与地形设定对照表'],
 ['03_建筑与聚落对照表.md','buildings','建筑与聚落设定对照表'],
 ['04_植物与环境装饰对照表.md','decoration','植物与环境装饰设定对照表'],
 ['06_交互与待确认边界.md','boundaries','交互与待确认边界'],
 ['原资产索引/地貌与地形对照表.md','terrain-assets','附录：地貌与地形原资产索引'],
 ['原资产索引/建筑与聚落对照表.md','building-assets','附录：建筑与聚落原资产索引'],
 ['原资产索引/植物与环境装饰对照表.md','decoration-assets','附录：植物与环境装饰原资产索引']
];
const sectionLinks=new Map(sections.map(([file,anchor])=>[path.resolve(dir,file),anchor]));
sectionLinks.set(path.join(dir,'README.md'),'contents');
const assetIndexes=new Map([['terrain','terrain-assets'],['buildings','building-assets'],['decoration','decoration-assets']]);

function transform(file,anchor,title){
 let text=read(file).replace(/^# .+\n+/,'');
 text=text.replace(/^\[返回目录\]\([^\n]*\)(?: · \[填写本类设定\]\([^\n]*\))?\n+/m,'');
 text=text.replace(/\[([^\]]+)\]\(([^)]+)\)/g,(all,label,url)=>{
  if(/^(https?:|#)/.test(url))return all;
  const resolved=path.resolve(path.dirname(path.join(dir,file)),url);
  if(sectionLinks.has(resolved))return `[${label}](#${sectionLinks.get(resolved)})`;
  return `[${label}](${path.relative(dir,resolved).replaceAll('\\','/')})`;
 });
 text=text.replace(/^(#{1,5}) /gm,'#$1 ');
 const appendix=anchor.endsWith('-assets');
 text=text.replace(/^(#{2,6}) ([TBD]\d{2}) (.+)$/gm,(all,level,unit,name)=>{
  const key=unit.toLowerCase();
  const id=(appendix?'asset-':'unit-')+key;
  const jump=appendix?`[查看本组设定与要求](#unit-${key})`:`[查看本组原资产逐条索引](#asset-${key})`;
  return `<a id="${id}"></a>\n\n${level} ${unit} ${name}\n\n${jump}`;
 });
 if(assetIndexes.has(anchor))text=text.replace(/^\| ([TBD]\d{2}) \|/gm,(_,unit)=>`| [${unit}](#unit-${unit.toLowerCase()}) |`);
 text=text.replaceAll('本页','本节');
 return `<a id="${anchor}"></a>\n\n## ${title}\n\n[返回总目录](#contents)\n\n${text}`;
}

const originalReadme=read('README.md');
const instructions=originalReadme.split('## 如何填，填到什么程度\n\n')[1].split('\n## 这份清单的覆盖范围')[0]
 .replaceAll('可直接编辑这些Markdown文件。','直接编辑本文件即可。下一步以你回填的本合并版为设定依据。');
const scope=originalReadme.split('## 这份清单的覆盖范围\n\n')[1].split('\n## 原资产逐条核对')[0];
const intro=`# 废土环境设定集：回填要求与原版／新版对照表（合并版）

2026-11-19。原版：**美国19世纪西部**；新版：**后启示录废土**。

本文件合并回填要求、全局设定、全部79个环境设计单元、生图规格、交互边界和原资产逐条索引。**只需回填这一份 Markdown**；其中“【待填】”和状态列是你的填写区，原版资料及工程约束已预填。旧分文件保留为初稿参考，后续以本合并版的回填内容为准。

<a id="contents"></a>

## 总目录

- [回填说明与覆盖范围](#instructions)
${sections.map(([,anchor,title])=>`- [${title}](#${anchor})`).join('\n')}

<a id="instructions"></a>

## 回填说明与覆盖范围

${instructions}

### 覆盖范围

${scope}

主表编号可跳到本组的原版配套与生图要求，再跳到文末逐资产索引。AF链接保留，可在[现有资产图示查询网站](https://afterfall-asset-catalog-20261118.neighborlynook32.chatgpt.site)查看原图与详情。废土方向示例均未自动采纳；你填写并标记“已确认”的内容才进入后续生图依据。本次合并未生成图片或更改Studio。
`;
const text=intro.trim()+'\n\n---\n\n'+sections.map(([file,anchor,title])=>transform(file,anchor,title)).join('\n\n---\n\n')+'\n';

// Verify content preservation and navigation before writing the single deliverable.
const errors=[];
const anchors=[...text.matchAll(/<a id="([^"]+)"><\/a>/g)].map(m=>m[1]);
const anchorSet=new Set(anchors);
if(anchorSet.size!==anchors.length)errors.push('重复锚点');
for(const [,url]of text.matchAll(/\[[^\]]*\]\(([^)]+)\)/g)){
 if(url.startsWith('#')){if(!anchorSet.has(url.slice(1)))errors.push('缺少锚点 '+url);}
 else if(!/^https?:/.test(url)&&!fs.existsSync(path.resolve(dir,url)))errors.push('缺少本地引用 '+url);
}
const mapping=JSON.parse(read('environment-mapping.json'));
for(const unit of mapping.units){
 if(!anchorSet.has('unit-'+unit.key.toLowerCase())||!anchorSet.has('asset-'+unit.key.toLowerCase()))errors.push('单元缺失 '+unit.key);
}
// Every source table row (including all fill cells) must remain intact except linked unit IDs.
for(const [file]of sections){
 const sourceRows=read(file).split('\n').filter(l=>l.startsWith('|'));
 for(let row of sourceRows){
  const normalized=row.replace(/^\| ([TBD]\d{2}) \|/,(_,key)=>`| [${key}](#unit-${key.toLowerCase()}) |`);
  if(!text.includes(row)&&!text.includes(normalized))errors.push('表格行缺失 '+file+': '+row.slice(0,80));
 }
}
let width=0;
for(const [i,line]of text.split('\n').entries()){
 if(line.startsWith('|')){
  const n=line.replaceAll('\\|','').split('|').length-2;
  if(width&&width!==n)errors.push('表格列不齐 '+(i+1));
  width=n;
 }else width=0;
}
if(errors.length)throw Error(errors.join('\n'));
fs.writeFileSync(target,text);
console.log(JSON.stringify({file:target,sourceDocuments:sections.length,designUnits:mapping.units.length,assignedAssets:mapping.assetMapping.length,boundaryAssets:mapping.boundaries.reduce((n,b)=>n+b.ids.length,0),lines:text.split('\n').length,bytes:Buffer.byteLength(text),anchors:anchors.length,errors},null,2));
