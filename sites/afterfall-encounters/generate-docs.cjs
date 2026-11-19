const fs=require('node:fs');
const path=require('node:path');
const d=require('./dist/data.js');
const out=path.join(__dirname,'dist','docs');fs.mkdirSync(out,{recursive:true});
const cat=id=>d.categories.find(c=>c.id===id).name;
const clean=s=>String(s).replaceAll('|','／').replaceAll('\n',' ');
const table=['# After Fall 副本与据点总览','',`静态快照：${d.snapshot}；Place ${d.placeId}。${d.method.counts}`,'','| 名称 | 分类 | 区域与占地 | 开启／生成 | 战斗 | 主要收益 | 刷新／状态 |','| --- | --- | --- | --- | --- | --- | --- |'];
for(const e of d.entries)table.push('| '+[e.name,cat(e.category),e.zone+' · '+e.size,e.trigger,e.encounter,e.reward,(e.status==='inactive'?'未启用；':'')+e.reset].map(clean).join(' | ')+' |');
table.push('','生成入口启用不等于每局成功落地。完整说明见《副本与据点详解》。');
fs.writeFileSync(path.join(out,'overview.md'),table.join('\n')+'\n');
const detail=['# After Fall 副本与据点详解','',d.method.scope,'',d.method.limits,''];
for(const e of d.entries){detail.push(`## ${e.name}`,``,`${cat(e.category)} · ${e.zone} · ${e.size} · ${e.status==='inactive'?'未启用':'生成入口启用（受条件约束）'}`,``,e.summary,``,`- 开启／生成：${e.trigger}`,`- 战斗：${e.encounter}`,`- 主要收益：${e.reward}`,`- 刷新：${e.reset}`,``);if(e.materials.length)detail.push('准备：'+e.materials.join('；'),'');for(const [t,b]of e.flow)detail.push(`### ${t}`,'',b,'');detail.push('### 战斗配置','');for(const [t,b]of e.combat)detail.push(`- ${t}：${b}`);detail.push('','### 奖励与循环','');for(const r of e.rewards)detail.push('- '+r);detail.push('',e.repeat,'','### 玩法设计解读','',e.design,'');if(e.hazards.length)detail.push('场景风险：'+e.hazards.join('；'),'');if(e.notes.length)detail.push(...e.notes.map(n=>'- '+n),'');detail.push('### 静态依据','',...e.sources.map(s=>'- `'+s.path+'`'+(s.lines?' '+s.lines:'')),'');}
fs.writeFileSync(path.join(out,'details.md'),detail.join('\n')+'\n');
fs.writeFileSync(path.join(out,'catalog.json'),JSON.stringify(d,null,2)+'\n');
const headers=['名称','分类','启用状态','区域','占地','入口条件','战斗','主要收益','刷新'];
const rows=d.entries.map(e=>[e.name,cat(e.category),e.status==='inactive'?'未启用':'条件生成',e.zone,e.size,e.trigger,e.encounter,e.reward,e.reset]);
const quote=s=>'"'+String(s).replaceAll('"','""')+'"';
fs.writeFileSync(path.join(out,'overview.csv'),'\ufeff'+[headers,...rows].map(r=>r.map(quote).join(',')).join('\r\n'));
console.log(JSON.stringify({entries:d.entries.length,documents:['overview.md','details.md','overview.csv','catalog.json']}));
